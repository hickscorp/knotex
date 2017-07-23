defmodule Block.Store do
  @moduledoc """
  Keeps an in-memory database of all block headers, allowing fast lookup of
  ancestry and hashes.
  """
  use GenServer
  require Logger
  alias __MODULE__, as: Store

  # Public API.

  @typep         state :: any
  @typep finder_result :: {:ok, Block.t} | {:error, :not_found | :badarg}

  @doc "Starts the block store."
  @spec start_link :: {:ok, pid}
  def start_link do
    GenServer.start_link Store, :ok, name: Store
  end

  @doc "Counts the blocks in the store."
  @spec count :: non_neg_integer
  def count do
    GenServer.call Store, :count
  end

  @doc "Adds a block to the store."
  @spec store(Block.t) :: Block.t
  def store(block) do
    GenServer.cast Store, {:store, block}
    block
  end

  @doc "Finds a block by its hash."
  @spec find_by_hash(Hash.t) :: finder_result
  def find_by_hash(nil), do: {:error, :badarg}
  def find_by_hash(hash), do: GenServer.call Store, {:find_by_hash, hash}

  @doc "Finds a block by its height and hash."
  @spec find_by_hash_and_height(Hash.t, Block.height) :: finder_result
  def find_by_hash_and_height(nil, _), do: {:error, :badarg}
  def find_by_hash_and_height(_, nil), do: {:error, :badarg}
  def find_by_hash_and_height(hash, height) do
    GenServer.call Store, {:find_by_hash_and_height, hash, height}
  end

  @doc "Removes a block from the store."
  @spec remove(Block.t) :: :ok
  def remove(%{} = block) do
    GenServer.cast Store, {:remove, block}
  end

  @doc "Clears the store completely."
  @spec clear :: :ok
  def clear do
    GenServer.cast Store, :clear
  end

  # GenServer callbacks.

  @spec init(:ok) :: {:ok, state}
  def init(:ok) do
    Logger.info fn -> "Starting an ETS backed store." end
    {:ok, :ets.new(Store, [:set, :private])}
  end

  @spec handle_call(:count, any, state) :: {:reply, non_neg_integer, state}
  def handle_call(:count, _from, table) do
    count = :ets.info table, :size
    {:reply, count, table}
  end

  @spec handle_call({:find_by_hash, Hash.t}, any, state)
                   :: {:reply, finder_result, state}
  def handle_call({:find_by_hash, hash}, _from, table) do
    ret = find_by(table, hash, :_, :_)
    {:reply, ret, table}
  end

  @spec handle_call({:find_by_hash_and_height, Hash.t, Block.height},
                    any, state) :: {:reply, finder_result, state}
  def handle_call({:find_by_hash_and_height, hash, height}, _from, table) do
    ret = find_by(table, hash, height, :_)
    {:reply, ret, table}
  end

  @spec handle_cast({:store, Block.t}, state) :: {:noreply, state}
  def handle_cast({:store, b}, table) do
    :ets.insert table, {b.hash, b.height, b.parent_hash, b}
    {:noreply, table}
  end

  @spec handle_cast({:remove, Block.t}, state) :: {:noreply, state}
  def handle_cast({:remove, b}, table) do
    :ets.match_delete table, {b.hash, b.height, b.parent_hash, b}
    {:noreply, table}
  end

  @spec handle_cast(:clear, state) :: {:noreply, state}
  def handle_cast(:clear, table) do
    true = :ets.delete_all_objects table
    {:noreply, table}
  end

  # Implementation.

  @spec find_by(state, Hash.t | :_, Block.height | :_, Hash.t | :_)
                :: finder_result
  defp find_by(table, hash, height, p_hash) do
    case :ets.match table, {hash, height, p_hash, :"$1"} do
      [[block]] -> {:ok, block}
      []        -> {:error, :not_found}
    end
  end
end
