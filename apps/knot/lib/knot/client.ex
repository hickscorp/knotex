defmodule Knot.Client do
  @moduledoc """
  Handles the communication between two nodes.
  """
  use GenServer
  require Logger
  alias __MODULE__, as: Client

  # Public API.

  @type         t :: pid
  @type direction :: :inbound | :outbound

  @ping_interval 5_000

  defmodule State do
    @moduledoc false
    @type t :: %State{
      logic:      Logic.t,
      socket:     Knot.socket,
      active_at:  integer
    }
    defstruct [
      logic:      nil,
      socket:     nil,
      active_at:  0
    ]
  end

  @spec start(Via.t, Knot.socket, Via.t, Client.direction) :: Client.t
  def start(clients, socket, logic, :inbound) do
    connect clients, socket, logic
  end
  def start(clients, socket, logic, :outbound) do
    clients
      |> connect(socket, logic)
      |> schedule_tick(@ping_interval)
  end

  @spec connect(Via.t, Knot.socket, Via.t) :: Client.t
  defp connect(clients, socket, logic) do
    {:ok, pid} = Supervisor.start_child clients, [socket, logic]
    pid
  end

  @spec close(Client.t) :: :ok
  def close(client) do
    GenServer.call client, :close
  end

  @spec send_data(Client.t, any) :: :ok
  def send_data(client, data) do
    GenServer.cast client, {:send_data, data}
  end

  # Supervisor callbacks.

  @spec start_link(Knot.socket, Via.t) :: {:ok, Client.t}
  def start_link(socket, logic) do
    GenServer.start_link Client, {socket, logic}
  end

  # GenServer callbacks.

  @spec init({Knot.socket, Via.t}) :: {:ok, State.t}
  def init({socket, logic}) do
    me = self()
    spawn_link fn -> recv me, socket end

    Knot.Logic.on_client_ready logic, me
    state = %State{logic: logic, socket: socket}
      |> mark_active
    {:ok, state}
  end

  @spec handle_call(:close, any, State.t) :: {:reply, :ok, State.t}
  def handle_call(:close, _from, %{socket: socket} = state) do
    :gen_tcp.close socket
    {:reply, :ok, state}
  end

  @spec handle_cast({:send_data, any}, State.t) :: {:noreply, State.t}
  def handle_cast({:send_data, data}, %{socket: socket} = state) do
    :ok = :gen_tcp.send socket, Bertex.encode data
    {:noreply, state}
  end

  @spec handle_cast({:on_data, binary}, State.t) :: {:noreply, State.t}
  def handle_cast({:on_data, data}, %{logic: logic} = state) do
    Knot.Logic.on_client_data logic, self(), data
    {:noreply, mark_active(state)}
  end

  @spec handle_cast(:on_close, State.t) :: {:noreply, State.t}
  def handle_cast(:on_close, %{logic: logic} = state) do
    me = self()
    Knot.Logic.on_client_closed logic, me
    {:stop, :normal, state}
  end

  @spec handle_info(:tick, State.t) :: {:noreply, State.t}
  def handle_info(:tick, state) do
    :ok = self()
      |> schedule_tick(@ping_interval)
      |> send_data({:ping, now()})
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
    DateTime.to_unix DateTime.utc_now()
  end

  @spec schedule_tick(Client.t, pos_integer) :: Client.t
  defp schedule_tick(pid, timeout) do
    Process.send_after pid, :tick, timeout
    pid
  end
end
