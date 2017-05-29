defmodule Explorer.Schema do
  @moduledoc false

  use Absinthe.Schema
  import_types Explorer.Schema.Types

  query do
    @desc "Get one block"
    field :block, type: :block do
      arg :id, non_null(:string)
      resolve &Explorer.BlockResolver.find/2
    end
  end
end
