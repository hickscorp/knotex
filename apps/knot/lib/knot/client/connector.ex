defmodule Knot.Client.Connector do
  @moduledoc """
  In charge of reaching for other nodes.

  Once connected, it ensures that the handshaking occurs and gives ownership
  of the socket to the handler process.
  """
  use GenServer
  require Logger
  alias __MODULE__, as: Connector
  alias Knot.{Via, Logic}

  # Public API.

  @type t :: Via.t | pid

  @spec start(Knot.Handle.t, Via.uri_or_address) :: Connector.t
  def start(%{connectors: connectors, logic: logic}, uri_or_address) do
    {:ok, pid} = connectors
      |> Supervisor.start_child([uri_or_address, logic])
    pid
  end

  # Supervisor callbacks.

  @spec start_link(Via.uri_or_address, Via.t) :: {:ok, Connector.t}
  def start_link(uri_or_address, handler) do
    {:ok, _} = GenServer.start_link Connector, {uri_or_address, handler}
  end

  # GenServer callbacks.

  @spec init({Via.uri_or_address, Via.t}) :: {:ok, {URI.t, Via.t}}
  def init({uri_or_address, handler}) do
    GenServer.cast self(), :connect
    {:ok, {URI.parse(uri_or_address), handler}}
  end

  @spec handle_cast(:connect, State.t) :: {:stop, :normal, State.t}
  def handle_cast(:connect, {uri, handler} = state) do
    with {:ok, socket} <- gen_tcp_connect(uri),
         reason <- transfer_socket_notify(socket, handler) do
      {:stop, reason, state}
    else
      {:error, :econnrefused} ->
        Logger.warn fn ->
          "Cannot connect to #{Via.to_string uri}: Connection refused."
        end
        {:stop, :normal, state}
      err ->
        Logger.error fn ->
          "An error occured while connecting to #{Via.to_string uri}: " <>
          inspect(err)
        end
        {:stop, :error, state}
    end
  end

  @spec gen_tcp_connect(URI.t) :: {:ok, Knot.socket} | {:error, any}
  defp gen_tcp_connect(%{host: host, port: port}) do
    :gen_tcp.connect to_charlist(host), port, [:binary, active: false]
  end

  @spec transfer_socket_notify(Knot.socket, Via.t) :: :normal | :error
  defp transfer_socket_notify(socket, handler) do
    with  handler_pid <- GenServer.call(handler, :pid),
          :ok <- :gen_tcp.controlling_process(socket, handler_pid),
          :ok <- Logic.on_client_socket(handler, socket, :outbound) do
          :normal
    else
        _ ->
          :error
    end
  end
end
