defmodule Knot.Logic do
  @moduledoc """
  Models the communication flow between nodes through clients.
  """
  use GenServer
  require Logger
  alias __MODULE__, as: Logic

  # Public API.

  @type t :: Via.t | pid

  defmodule State do
    @moduledoc false
    alias __MODULE__, as: State

    @type t :: %State{
      uri:      URI.t,
      clients:  list(Knot.socket)
    }
    defstruct [
      uri:      nil,
      clients:  []
    ]

    @spec new(URI.t) :: t
    def new(uri) do
      %State{uri: uri}
    end
  end

  @spec start_link(URI.t) :: {:ok, Logic.t}
  def start_link(uri) do
    GenServer.start_link Logic, uri, name: Via.logic(uri)
  end

  # GenServer handlers.
  @spec init(URI.t) :: {:ok, State.t}
  def init(uri) do
    Logger.info fn -> "[#{Via.readable uri}] Starting logic." end
    {:ok, State.new(uri)}
  end

  @spec handle_call(:pid, any, State.t) :: {:reply, pid, State.t}
  def handle_call(:pid, _from, state) do
    {:reply, self(), state}
  end

  @spec handle_call({:on_listener_terminating, any}, any, State.t)
                   :: {:reply, :ok, State.t}
  def handle_call({:on_listener_terminating, reason}, _from, state) do
    Logger.info fn ->
      "[#{Via.readable state.uri}] Logic is terminating: #{reason}. " <>
      "Notifying #{inspect length state.clients} client(s)..."
    end
    for client <- state.clients, do: Knot.Client.close client
    {:reply, :ok, state}
  end

  @spec handle_cast({:on_client_socket, Knot.socket, Client.direction}, State.t)
                   :: {:noreply, State.t}
  def handle_cast({:on_client_socket, cli_socket, direction}, state) do
    Logger.info fn ->
      "[#{Via.readable state.uri}] New #{direction} client socket."
    end
    Knot.Client.start cli_socket, Via.logic(state.uri), direction
    {:noreply, state}
  end

  @spec handle_cast({:on_client_ready, Client.t}, State.t)
                   :: {:noreply, State.t}
  def handle_cast({:on_client_ready, client}, state) do
    new_state = %{state | clients: [client | state.clients]}

    Enum.each [:genesis, :heighest],
              &Knot.Client.send_data(client, {:block_query, &1})

    {:noreply, new_state}
  end

  def handle_cast({:on_client_data, client, data}, %{uri: uri} = state) do
    case deserialize data do
      {:ok, terms} -> on_client_data state, client, terms
      {:error, e} ->
        Logger.error "[#{Via.readable uri}] Cannot decode message: #{inspect e}"
    end

    {:noreply, state}
  end

  def handle_cast({:on_client_closed, client}, state) do
    Logger.info fn ->
      "[#{Via.readable state.uri}] Removing disconnected client."
    end
    {:noreply, %{state | clients: Enum.filter(state.clients, &(&1 != client))}}
  end

  # Implementation.

  def deserialize(data) do
    try do
      {:ok, Bertex.safe_decode(data)}
    rescue
      e -> {:error, e}
    end
  end

  @spec on_client_data(State.t, Knot.socket, any) :: any
  # Received ping, answer pong.
  def on_client_data(%{uri: uri}, client, {:ping, ts}) do
    Logger.info fn ->
      "[#{Via.readable uri}] Received ping at #{ts} from #{inspect client}."
    end
    Knot.Client.send_data client, :pong
  end
  # Received pong.
  def on_client_data(%{uri: uri}, client, :pong) do
    Logger.info fn ->
      "[#{Via.readable uri}] Received pong from #{inspect client}."
    end
  end
  # Received a block query.
  def on_client_data(%{uri: uri}, client, {:block_query, query}) do
    process_block_query uri, client, query
  end
  # Received an answer to a query.
  def on_client_data(%{uri: uri}, client, {:answer, {query, _}}) do
    case query do
      :genesis ->
        Logger.info fn ->
          "[#{Via.readable uri}] #{inspect client} knows the remote genesis."
        end
      :heighest ->
        Logger.info fn ->
          "[#{Via.readable uri}] #{inspect client} knows the remote highest " <>
          "block."
        end
    end
  end
  # Unknown command.
  def on_client_data(%{uri: uri}, _, cmd) do
    Logger.warn fn ->
      "[#{Via.readable uri}] Unknown command from client: #{inspect cmd}"
    end
  end

  def process_block_query(_, _, :genesis) do
    Block.genesis()
  end
  def process_block_query(_, _, :highest) do
    # TODO: Fetch the highest block from the node state.
    Block.new <<1>>, 382_921_200
  end
  def process_block_query(_, _, {:ancestry, hash}) do
    # TODO: Get ancestry up to `hash`.
    :ok
  end
  def process_block_query(uri, client, query) do
    {:error, :invalid_block_query}
  end
end
