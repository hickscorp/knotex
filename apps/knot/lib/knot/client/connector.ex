defmodule Knot.Client.Connector do
  @moduledoc """
  In charge of reaching for other nodes.

  Once connected, it ensures that the handshaking occurs and gives ownership
  of the socket to the handler process.
  """
  use GenServer
  require Logger
  alias __MODULE__, as: Connector

  # Public API.

  @type t :: Via.t | pid

  @spec start(URI.t | String.t, Via.t) :: Connector.t
  def start(%URI{} = uri, handler) do
    {:ok, pid} = Supervisor.start_child Knot.Connectors, [uri, handler]
    pid
  end
  def start(uri, handler) when is_binary uri do
    start URI.parse(uri), handler
  end

  # Supervisor callbacks.

  @spec start_link(URI.t, Via.t) :: {:ok, Connector.t}
  def start_link(uri, handler) do
    {:ok, _} = GenServer.start_link Connector, {uri, handler}
  end

  # GenServer callbacks.

  @spec init({URI.t, Via.t}) :: {:ok, {URI.t, Via.t}}
  def init({uri, handler}) do
    GenServer.cast self(), :connect
    {:ok, {uri, handler}}
  end

  @spec handle_cast(:connect, State.t) :: {:stop, :normal, State.t}
  def handle_cast(:connect, {%{host: host, port: port}, handler} = state) do
    reason = host
      |> String.to_charlist
      |> :gen_tcp.connect(port, [:binary, active: false])
      |> transfer_socket_notify(handler)
    {:stop, reason, state}
  end

  @spec transfer_socket_notify({:ok, Knot.socket}, Via.t) :: :normal | :error
  defp transfer_socket_notify({:ok, socket}, handler) do
    with  handler_pid <- GenServer.call(handler, :pid),
          :ok <- :gen_tcp.controlling_process(socket, handler_pid),
          opts <- {:on_client_socket, socket, :outbound},
          :ok <- GenServer.cast(handler, opts) do
          :normal
    else
        _ ->
          :error
    end
  end
end
