defmodule Explorer.BlockView do
  @moduledoc false
  use Explorer, :view
  alias Explorer.BlockView
  alias Knot.Hash

  @spec render(String.t, map) :: map
  def render("ancestry.json", %{blocks: blocks}) do
    %{data: render_many(blocks, BlockView, "block.json")}
  end
  def render("show.json", %{block: block}) do
    %{data: render_one(block, BlockView, "block.json")}
  end
  def render("block.json", %{block: block}) do
    %{
              height: block.height,
           timestamp: block.timestamp,
         parent_hash: Hash.readable(block.parent_hash),
        content_hash: Hash.readable(block.content_hash),
      component_hash: Hash.readable(block.component_hash),
               nonce: block.nonce,
                hash: Hash.readable(block.hash)
    }
  end
end
