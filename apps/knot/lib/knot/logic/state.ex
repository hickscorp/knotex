defmodule Knot.Logic.State do
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
  def new(uri), do: %State{uri: uri, clients: [], chain: [Block.genesis()]}

  @spec add_client(t, Client.t) :: t
  def add_client(%{clients: clients} = state, client) do
    %{state | clients: [client] ++ clients}
  end

  @spec remove_client(t, Client.t) :: t
  def remove_client(%{clients: clients} = state, client) do
    %{state | clients: Enum.filter(clients, &Kernel.!=(client, &1))}
  end
end
