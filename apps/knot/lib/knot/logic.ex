defmodule Knot.Logic do
  @moduledoc """
  Models the communication flow between nodes through clients.
  """
  use GenServer
  require Logger
  alias __MODULE__, as: Logic
  alias Knot.{Block, Block.Store, Block.Miner, Hash, Via, Client}
  alias Knot.Logic.State, as: State

  # Public API.

  @type t :: Via.t | pid

  @spec start_link(URI.t, Block.t) :: {:ok, Logic.t}
  def start_link(uri, genesis) do
    GenServer.start_link Logic, {uri, genesis}, name: Via.logic(uri)
  end

  @spec seed(Logic.t, integer) :: Block.t
  def seed(logic, count \\ 128) do
    {:ok, head} = State.find state(logic), "head"
    Enum.reduce 1..count, head, fn (offset, parent) ->
      Logger.info fn -> "Seeding #{offset}." end
      block = "A block at height #{parent.height + 1}"
        |> Hash.perform
        |> Block.new(:os.system_time(:millisecond))
        |> Block.as_child_of(parent)
        |> Block.seal
        |> Miner.mine

      :ok = Logic.push logic, block
      block
    end
  end

  @spec pid(Logic.t) :: pid
  def pid(logic) do
    GenServer.call logic, :pid
  end

  @spec state(Logic.t) :: State.t
  def state(logic) do
    GenServer.call logic, :state
  end

  @spec find(Logic.t, Block.id) :: {:ok, Block.t} | {:error, atom}
  def find(logic, id) do
    logic
      |> state
      |> State.find(id)
  end

  @spec ancestry(Logic.t, Block.t, integer)
                :: {:ok, list(Block.t)} | {:error, atom}
  def ancestry(logic, %{hash: hash}, top) do
    ancestry logic, hash, top
  end
  def ancestry(logic, hash, top) do
    logic
      |> state
      |> State.ancestry(hash, top)
  end

  @spec push(Logic.t, Block.t) :: :ok | {:error, atom}
  def push(logic, block) do
    GenServer.call logic, {:push, block}
  end

  @spec on_listener_terminating(Logic.t, any) :: :ok
  def on_listener_terminating(logic, reason) do
    GenServer.cast logic, {:on_listener_terminating, reason}
  end

  @spec on_client_socket(Logic.t, Socket.t, Client.direction) :: :ok
  def on_client_socket(logic, cli_socket, direction) do
    GenServer.cast logic, {:on_client_socket, cli_socket, direction}
  end

  @spec on_client_ready(Logic.t, Client.t) :: :ok
  def on_client_ready(logic, client) do
    GenServer.cast logic, {:on_client_ready, client}
  end

  @spec on_client_data(Logic.t, Client.t, any) :: :ok
  def on_client_data(logic, client, data) do
    GenServer.cast logic, {:on_client_data, client, data}
  end

  @spec on_client_closed(Logic.t, Client.t) :: :ok
  def on_client_closed(logic, client) do
    GenServer.cast logic, {:on_client_closed, client}
  end

  # GenServer handlers.

  @spec init({URI.t, Block.t}) :: {:ok, State.t}
  def init({uri, genesis}) do
    Logger.info fn -> "[#{Via.readable uri}] Starting logic." end
    {:ok, ^genesis} = Block.Store.store genesis
    {:ok, State.new(uri, genesis)}
  end

  @spec handle_call(:pid, any, State.t) :: {:reply, pid, State.t}
  def handle_call(:pid, _from, state) do
    {:reply, self(), state}
  end

  @spec handle_call(:state, any, State.t) :: {:reply, State.t, State.t}
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @spec handle_call({:push, Block.t}, any, State.t)
                   :: {:reply, :ok | {:error, atom}, State.t}
  def handle_call({:push, block}, _from, state) do
    with :ok <- Block.ensure_mined(block),
         {:ok, ^block} <- Store.store(block) do
      {:reply, :ok, %{state | head: block}}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
                     _ -> {:reply, {:error, :push_error}, state}
    end
  end

  @spec handle_call({:on_listener_terminating, any}, any, State.t)
                   :: {:reply, :ok, State.t}
  def handle_call({:on_listener_terminating, reason}, _from, state) do
    Logger.info fn ->
      "[#{Via.readable state.uri}] Logic is terminating: #{reason}. " <>
      "Notifying #{inspect length state.clients} client(s)..."
    end
    for client <- state.clients, do: Client.close client
    {:reply, :ok, state}
  end

  @spec handle_cast({:on_client_socket, Knot.socket, Client.direction}, State.t)
                   :: {:noreply, State.t}
  def handle_cast({:on_client_socket, cli_socket, direction}, state) do
    Logger.info fn ->
      "[#{Via.readable state.uri}] New #{direction} client socket."
    end
    Client.start cli_socket, Via.logic(state.uri), direction
    {:noreply, state}
  end

  @spec handle_cast({:on_client_ready, Client.t}, State.t)
                   :: {:noreply, State.t}
  def handle_cast({:on_client_ready, client}, state) do
    [:genesis, :heighest]
      |> Enum.each(&Client.send_data(client, {:query, &1}))
    {:noreply, State.add_client(state, client)}
  end

  @spec handle_cast({:on_client_data, Client.t, any}, State.t)
                   :: {:noreply, State.t}
  def handle_cast({:on_client_data, client, data}, %{uri: uri} = state) do
    case deserialize data do
      {:ok, terms} -> process_client_data terms, state, client
      {:error, e} ->
        Logger.error "[#{Via.readable uri}] Cannot decode message: #{inspect e}"
    end
    {:noreply, state}
  end

  @spec handle_cast({:on_client_closed, Client.t}, State.t)
                   :: {:noreply, State.t}
  def handle_cast({:on_client_closed, client}, state) do
    Logger.info fn ->
      "[#{Via.readable state.uri}] Removing disconnected client."
    end
    {:noreply, State.remove_client(state, client)}
  end

  # Implementation.

  @spec deserialize(any) :: {:ok, any} | {:error, atom}
  def deserialize(data) do
    {:ok, Bertex.safe_decode(data)}
  rescue
    e -> {:error, e}
  end

  @spec process_client_data(any, State.t, Knot.socket) :: any
  def process_client_data({:ping, ts}, %{uri: uri}, client) do
    Logger.info fn ->
      "[#{Via.readable uri}] Received ping at #{ts} from #{inspect client}."
    end
    Client.send_data client, :pong
  end
  def process_client_data(:pong, %{uri: uri}, client) do
    Logger.info fn ->
      "[#{Via.readable uri}] Received pong from #{inspect client}."
    end
  end
  def process_client_data({:query, q}, state, _client) do
    case q do
              {:block, id} -> State.find state, id
      {:ancestry, id, top} -> State.ancestry state, id, top
                 _         -> {:error, :unknown_query}
    end
  end
  def process_client_data(cmd, %{uri: uri}, _) do
    Logger.warn fn ->
      "[#{Via.readable uri}] Unknown command from client: #{inspect cmd}"
    end
  end
end
