defmodule Knot.Client do
  @moduledoc """
  Handles the communication between two nodes.
  """
  use GenServer
  require Logger
  alias __MODULE__, as: Client

  # Public API.

  @type         t :: Via.t | pid
  @type direction :: :inbound | :outbound

  defmodule State do
    @moduledoc false
    @type t :: %State{
      handler:    Via.t,
      socket:     Knot.socket,
      active_at:  integer
    }
    defstruct [
      handler:    nil,
      socket:     nil,
      active_at:  0
    ]
  end

  @spec start(Knot.socket, Via.t, Client.direction) :: Client.t
  def start(socket, handler, :inbound) do
    socket
      |> connect(handler)
  end
  def start(socket, handler, :outbound) do
    socket
     |> connect(handler)
     |> schedule_tick(500)
  end

  @spec connect(Knot.socket, Via.t) :: Client.t
  defp connect(socket, handler) do
    {:ok, pid} = Supervisor.start_child Knot.Clients, [socket, handler]
    pid
  end

  @spec send_data(Client.t, any) :: :ok
  def send_data(client, data) do
    GenServer.cast client, {:send_data, data}
  end

  # Supervisor callbacks.

  @spec start_link(Knot.socket, Via.t) :: {:ok, Client.t}
  def start_link(socket, handler) do
    GenServer.start_link Client, {socket, handler}
  end

  # GenServer callbacks.

  @spec init({Knot.socket, Via.t}) :: {:ok, State.t}
  def init({socket, handler}) do
    me = self()
    spawn fn -> recv me, socket end

    GenServer.cast handler, {:on_client_ready, me}
    state = %State{handler: handler, socket: socket}
      |> mark_active
    {:ok, state}
  end

  def handle_cast({:send_data, data}, %{socket: socket} = state) do
    :ok = :gen_tcp.send socket, Bertex.encode data
    {:noreply, state}
  end

  @spec handle_cast({:on_data, binary}, State.t) :: {:noreply, State.t}
  def handle_cast({:on_data, data}, %{handler: handler} = state) do
    GenServer.cast handler, {:on_client_data, self(), data}
    {:noreply, mark_active(state)}
  end

  @spec handle_cast(:on_close, State.t) :: {:noreply, State.t}
  def handle_cast(:on_close, %{handler: handler} = state) do
    me = self()
    GenServer.cast handler, {:on_client_closed, me}
    {:stop, :normal, state}
  end

  def handle_info(:tick, state) do
    me = self()
      |> schedule_tick(5_000)
    :ok = send_data me, {:ping, now()}
    {:noreply, state}
 end

  # Implementation.

  @spec recv(pid, Knot.socket) :: :ok | {:error, any}
  defp recv(client, socket) do
    case :gen_tcp.recv socket, 0 do
      {:ok, data} ->
        GenServer.cast client, {:on_data, data}
        recv client, socket
      {:error, :closed} ->
        GenServer.cast client, :on_close
      otherwise ->
        Logger.warn fn -> "Unhandled client message: #{inspect otherwise}" end
        GenServer.cast client, :on_close
        {:error, otherwise}
    end
  end

  @spec mark_active(State.t) :: State.t
  defp mark_active(state) do
    %{state | active_at: now()}
  end

  @spec now :: pos_integer
  defp now do
    DateTime.utc_now
      |> DateTime.to_unix
  end

  @spec schedule_tick(Client.t, pos_integer) :: Client.t
  defp schedule_tick(pid, timeout) do
    Process.send_after pid, :tick, timeout
    pid
  end
end
