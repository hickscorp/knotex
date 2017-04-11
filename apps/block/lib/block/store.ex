require Logger

defmodule Block.Store do
  @moduledoc """
  Keeps an in-memory database of all block headers, allowing fast lookup of
  ancestry and hashes.
  """
  use GenServer
  alias __MODULE__, as: Store

  # Public API.

  @type         state :: any
  @type finder_result :: {:ok, Block.t} | {:error, :not_found | :badarg}

  @spec start_link :: {:ok, pid}
  def start_link do
    GenServer.start_link Store, :ok, name: Store
  end

  @spec count :: non_neg_integer
  def count do
    GenServer.call Store, :count
  end

  @spec store(Block.t) :: Block.t
  def store(block) do
    GenServer.cast Store, {:store, block}
    block
  end

  @spec find_by_hash(Hash.t) :: finder_result
  def find_by_hash(nil), do: {:error, :badarg}
  def find_by_hash(hash), do: GenServer.call Store, {:find_by_hash, hash}

  @spec find_by_height_and_hash(Block.height, Hash.t) :: finder_result
  def find_by_height_and_hash(nil, _), do: {:error, :badarg}
  def find_by_height_and_hash(_, nil), do: {:error, :badarg}
  def find_by_height_and_hash(height, hash) do
    GenServer.call Store, {:find_by_height_and_hash, height, hash}
  end

  @spec remove(Block.t | Hash.t) :: :ok
  def remove(block) do
    GenServer.cast Store, {:remove, block}
  end

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
    ret = find_by(table, :_, hash, :_)
    {:reply, ret, table}
  end

  @spec handle_call({:find_by_height_and_hash, Block.height, Hash.t},
                    any, state) :: {:reply, finder_result, state}
  def handle_call({:find_by_height_and_hash, height, hash}, _from, table) do
    ret = find_by(table, height, hash, :_)
    {:reply, ret, table}
  end

  @spec handle_cast({:store, Block.t}, state) :: {:noreply, state}
  def handle_cast({:store, b}, table) do
    :ets.insert table, {b.height, b.hash, b.parent_hash, b}
    {:noreply, table}
  end

  @spec handle_cast({:remove, Block.t}, state) :: {:noreply, state}
  def handle_cast({:remove, b}, table) do
    # TODO: Fix.
    :ets.delete table, {b.height, b.hash, b.parent_hash, b}
    {:noreply, table}
  end

  @spec handle_cast(:clear, state) :: {:noreply, state}
  def handle_cast(:clear, table) do
    true = :ets.delete_all_objects table
    {:noreply, table}
  end

  # Implementation.

  @spec find_by(state, Block.height | :_, Hash.t | :_, Hash.t | :_)
                :: finder_result
  defp find_by(table, height, hash, p_hash) do
    case :ets.match table, {height, hash, p_hash, :"$1"} do
      [[block]] -> {:ok, block}
      []        -> {:error, :not_found}
    end
  end
end
