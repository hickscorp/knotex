defmodule Block.Application do
  @moduledoc false

  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      worker(Block.Store, []),
    ]

    Supervisor.start_link children, strategy: :one_for_one
  end
end
