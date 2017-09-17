defmodule Knot.Listener do
  @moduledoc """
  A TCP acceptor to allow inbound client connections.
  """
  use GenServer
  require Logger
  alias __MODULE__, as: Listener
  alias Knot.Via

  # Public API.

  @type t :: Via.t | pid

  @spec start_link(Via.uri_or_address) :: {:ok, Listener.t}
  def start_link(uri_or_address) do
    ref = Via.listener uri_or_address
    GenServer.start_link Listener, uri_or_address, name: ref
  end

  # GenServer handlers.

  @spec init(Via.uri_or_address) :: {:ok, State.t}
  def init(uri_or_address) do
    uri = URI.parse uri_or_address
    Process.flag :trap_exit, true
    Logger.info fn -> "[#{Via.to_string uri}] Starting listener." end

    host = String.to_charlist uri.host
    {:ok, ip} = :inet.getaddr host, :inet

    opts = [:binary, ip: ip, packet: 0, active: false]
    {:ok, socket} = :gen_tcp.listen uri.port, opts
    spawn_link fn -> listen uri, socket end

    {:ok, {uri, socket}}
  end

  # Implementation.

  @spec listen(URI.t, Knot.socket) :: any
  defp listen(uri, socket) do
    case :gen_tcp.accept socket do
      {:ok, cli_socket} ->
        uri
          |> Via.logic
          |> Knot.Logic.on_client_socket(cli_socket, :inbound)
        listen uri, socket
      {:error, :closed} ->
        Logger.info fn ->
          "[#{Via.to_string uri}] Socket was closed."
        end
        :ok
      {:error, err} ->
        Logger.warn fn ->
          "[#{Via.to_string uri}] Unable to accept: #{inspect err}"
        end
        {:error, err}
    end
  end

  @spec terminate(any, {Via.uri_or_address, Knot.socket}) :: :ok
  def terminate(reason, {uri_or_address, socket}) do
    uri = URI.parse uri_or_address
    Logger.info fn ->
      "[#{Via.to_string uri}] Terminating listener: #{inspect reason}."
    end
    uri
      |> Via.logic
      |> Knot.Logic.on_listener_terminating(reason)
    :gen_tcp.close socket
  end
end
