defmodule Explorer.Schema.Types do
  @moduledoc false
  use Absinthe.Schema.Notation
  alias Explorer.BlockResolver

  @desc "A 32-bit hash"
  scalar :hash do
    parse     &Knot.Hash.from_string(&1)
    serialize &Knot.Hash.to_string(&1)
  end

  @desc "A block"
  object :block do
    field :height, :integer
    field :nonce, :integer
    field :hash, :hash
    field :parent_hash, :hash
    field :content_hash, :hash
    field :component_hash, :hash

    field :parent, :block do
      resolve fn block, _, _ ->
        params = %{id: block.parent_hash}
        BlockResolver.find params, nil
      end
    end

    field :ancestry, list_of(:block) do
      arg :top, :integer
      resolve fn block, args, _ ->
        params = Map.merge %{block: block, top: 5}, args
        BlockResolver.ancestry params, nil
      end
    end
  end
end
