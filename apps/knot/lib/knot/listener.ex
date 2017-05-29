defmodule Knot.Listener do
  @moduledoc """
  A TCP acceptor to allow inbound client connections.
  """
  use GenServer
  require Logger
  alias __MODULE__, as: Listener

  # Public API.

  @type t :: Via.t | pid

  @spec start_link(URI.t, Via.t | pid) :: {:ok, Listener.t}
  def start_link(uri, handler) do
    ref = Via.listener uri
    GenServer.start_link Listener, {uri, handler}, name: ref
  end

  # GenServer handlers.

  @spec init({URI.t, Via.t}) :: {:ok, State.t}
  def init({uri, handler}) do
    Process.flag :trap_exit, true
    Logger.info fn -> "[#{Via.readable uri}] Starting listener." end

    host = String.to_charlist uri.host
    {:ok, ip} = :inet.getaddr host, :inet

    opts = [:binary, ip: ip, packet: 0, active: false]
    {:ok, socket} = :gen_tcp.listen uri.port, opts
    spawn_link fn -> listen uri, handler, socket end

    {:ok, {uri, handler, socket}}
  end

  # Implementation.

  @spec listen(URI.t, Via.t, Knot.socket) :: any
  defp listen(uri, handler, socket) do
    case :gen_tcp.accept socket do
      {:ok, cli_socket} ->
        GenServer.cast handler, {:on_client_socket, cli_socket, :inbound}
        listen uri, handler, socket
      {:error, :closed} ->
        Logger.info fn ->
          "[#{Via.readable uri}] Socket was closed."
        end
        :ok
      {:error, err} ->
        Logger.warn fn ->
          "[#{Via.readable uri}] Unable to accept: #{inspect err}"
        end
        {:error, err}
    end
  end

  def terminate(reason, {uri, handler, socket}) do
    Logger.info fn ->
      "[#{Via.readable uri}] Terminating listener: #{inspect reason}."
    end
    GenServer.call handler, {:on_listener_terminating, reason}
    :gen_tcp.close socket
  end
end
