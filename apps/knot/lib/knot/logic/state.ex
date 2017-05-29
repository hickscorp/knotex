defmodule Knot.Logic.State do
  @moduledoc false
  alias __MODULE__, as: State
  alias Knot.{Hash, Block, Block.Store}

  @typep t :: %State{
    uri:            URI.t,
    clients:        list(Knot.socket),
    genesis:        Block.t,
    head:           Block.t
  }
  defstruct [
    uri:            nil,
    clients:        [],
    genesis:        nil,
    head:           nil
  ]

  @spec new(URI.t, Block.t) :: t
  def new(uri, genesis) do
    %State{
      uri:      uri,
      clients:  [],
      genesis:  genesis,
      head:     genesis
    }
  end

  @spec add_client(t, Client.t) :: t
  def add_client(%{clients: clients} = state, client) do
    %{state | clients: [client] ++ clients}
  end

  @spec remove_client(t, Client.t) :: t
  def remove_client(%{clients: clients} = state, client) do
    %{state | clients: Enum.filter(clients, &Kernel.!=(client, &1))}
  end

  @spec find(State.t, Block.id) :: {:ok, Block.t} | {:error, atom}
  def find(%{genesis: genesis}, "genesis") do
    {:ok, genesis}
  end
  def find(%{head: head}, "head") do
    {:ok, head}
  end
  def find(state, hash) when byte_size(hash) == 64 do
    find state, Hash.from_string(hash)
  end
  def find(_, hash) do
    Block.Store.find_by_hash hash
  end

  @spec ancestry(State.t, Hash.t, integer)
                :: {:ok, list(Block.t)} | {:error, atom}
  def ancestry(_, hash, top \\ 5) do
    with {:ok, block} <- Store.find_by_hash(hash) do
         Block.ancestry block, top
    else
      err -> err
    end
  end
end
