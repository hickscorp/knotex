defmodule Knot.Block.Store do
  @moduledoc """
  Keeps an in-memory database of all block headers, allowing fast lookup of
  ancestry and hashes.
  """
  use GenServer
  require Logger
  alias __MODULE__, as: Store
  alias Knot.{Block, Hash}

  # Public API.

  @typep        state  :: {:ets | :dets, any}
  @type  finder_error  :: :not_found | :badarg
  @type   insert_error :: :insert_error
  @type finder_result  :: {:ok, Block.t} | {:error, finder_error}

  @doc "Starts the block store."
  @spec start_link :: {:ok, pid}
  def start_link do
    GenServer.start_link Store, :ok, name: Store
  end

  @doc "Adds a block to the store."
  @spec store(Block.t) :: :ok | {:error, insert_error}
  def store(block) do
    case GenServer.call Store, {:store, block} do
      val when val == true or val == :ok -> {:ok, block}
                                       _ -> {:error, :insert_error}
    end
  end

  @doc "Counts the blocks in the store."
  @spec count :: non_neg_integer
  def count do
    GenServer.call Store, :count
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
    backend = Application.get_env :knot, :block_store_backend
    Logger.info fn -> "Starting #{backend} backed store." end
    {:ok, table} = case backend do
       :ets -> {:ok, :ets.new(Store, [:set, :private])}
      :dets -> :dets.open_file :block_store, [type: :set]
    end
    {:ok, {backend, table}}
  end

  @spec handle_call({:store, Block.t}, any, state)
                   :: {:reply, {:ok, Block.t} | {:error, insert_error}, state}
  def handle_call({:store, b}, _from, {backend, table} = state) do
    args = [table, {b.hash, b.height, b.parent_hash, b}]
    ret = Kernel.apply backend, :insert, args
    {:reply, ret, state}
  end

  @spec handle_call(:count, any, state) :: {:reply, non_neg_integer, state}
  def handle_call(:count, _from, {backend, table} = state) do
    size = Kernel.apply backend, :info, [table, :size]
    {:reply, size, state}
  end

  @spec handle_call({:find_by_hash, Hash.t}, any, state)
                   :: {:reply, finder_result, state}
  def handle_call({:find_by_hash, hash}, _from, state) do
    ret = find_by(state, hash, :_, :_)
    {:reply, ret, state}
  end

  @spec handle_call({:find_by_hash_and_height, Hash.t, Block.height},
                    any, state) :: {:reply, finder_result, state}
  def handle_call({:find_by_hash_and_height, hash, height}, _from, state) do
    ret = find_by state, hash, height, :_
    {:reply, ret, state}
  end

  @spec handle_cast({:remove, Block.t}, state) :: {:noreply, state}
  def handle_cast({:remove, b}, {backend, table} = state) do
    Kernel.apply backend, :match_delete, [table, {b.hash, b.height, b.parent_hash, b}]
    {:noreply, state}
  end

  @spec handle_cast(:clear, state) :: {:noreply, state}
  def handle_cast(:clear, {backend, table} = state) do
    Kernel.apply backend, :delete_all_objects, [table]
    {:noreply, state}
  end

  # Implementation.

  @spec find_by(state, Hash.t | :_, Block.height | :_, Hash.t | :_)
                :: finder_result
  defp find_by({backend, table}, hash, height, p_hash) do
    args = [table, {hash, height, p_hash, :"$1"}]
    res = backend
      |> Kernel.apply(:match, args)
    case res do
      [[block]] -> {:ok, block}
      []        -> {:error, :not_found}
    end
  end
end
