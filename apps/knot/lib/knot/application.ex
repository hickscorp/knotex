defmodule Knot.Application do
  @moduledoc false
  use Application

  @spec start(any, any) :: {:ok, pid}
  def start(_type, _args) do
    import Supervisor.Spec
    import Knot.SofoSupervisor.Spec

    children = [
      supervisor(Knot.Repo, []),
      worker(Registry, [:unique, Knot.Via.registry()]),
      sofo(Knot.Knots, Knot)
    ]
    Supervisor.start_link children, strategy: :one_for_one
  end
end
