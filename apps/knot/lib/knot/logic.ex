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

    @typep t :: %State{
      uri:            URI.t,
      clients:        list(Knot.socket),
      chain:          list(Block.t)
    }
    defstruct [
      uri:            nil,
      clients:        [],
      chain:          []
    ]

    @spec new(URI.t) :: t
    def new(uri) do
      %State{
        uri: uri,
        clients: [],
        chain: [Block.genesis()]
      }
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
      {:ok, terms} -> on_client_data terms, state, client
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

  @spec on_client_data(any, State.t, Knot.socket) :: any
  # Received ping, answer pong.
  def on_client_data({:ping, ts}, %{uri: uri}, client) do
    Logger.info fn ->
      "[#{Via.readable uri}] Received ping at #{ts} from #{inspect client}."
    end
    Knot.Client.send_data client, :pong
  end
  # Received pong.
  def on_client_data(:pong, %{uri: uri}, client) do
    Logger.info fn ->
      "[#{Via.readable uri}] Received pong from #{inspect client}."
    end
  end
  # Received a block query.
  def on_client_data({:block_query, query}, state, client) do
    process_block_query query, state, client
  end
  # Received an answer to a query.
  def on_client_data({:answer, {query, _}}, %{uri: uri}, client) do
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
  def on_client_data(cmd, %{uri: uri}, _) do
    Logger.warn fn ->
      "[#{Via.readable uri}] Unknown command from client: #{inspect cmd}"
    end
  end

  def process_block_query(:genesis, _, _) do
    Block.genesis()
  end
  def process_block_query(:highest, state, _) do
    hd state.chain
  end
  def process_block_query({:ancestry, hash}, _, _) do
    case Block.Store.find_by_hash hash do
      {:ok, block} -> Block.ancestry block
      _ -> {:error, :unknown_block_hash}
    end
  end
  def process_block_query(_query, _state, _client) do
    {:error, :invalid_block_query}
  end
end
