defmodule Explorer.BlockResolver do
  @moduledoc false

  @spec ancestry(%{block: Block.t, top: integer}, any)
                :: {:ok, list(Block.t)} | {:error, atom}
  def ancestry(%{block: block, top: top}, _info) do
    Knot.Logic.ancestry logic(), block, top
  end

  @spec find(%{id: Block.id}, any) :: {:ok, list(Block.t)} | {:error, atom}
  def find(%{id: id}, _info) do
    Knot.Logic.find logic(), id
  end

  @spec logic :: Knot.Logic.t
  defp logic do
    genesis = :knot
      |> Application.get_env(:genesis_data)
      |> Knot.Block.genesis
    "tcp://127.0.0.1:4001"
      |> Knot.start(genesis)
      |> Map.get(:logic)
  end
end
