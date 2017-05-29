defmodule Knot.Application do
  @moduledoc false
  use Application

  @spec start(any, any) :: {:ok, pid}
  def start(_type, _args) do
    import Supervisor.Spec
    import Knot.SofoSupervisor.Spec

    children = [
      worker(Registry, [:unique, Knot.Via.registry()]),
      worker(Knot.Block.Store, []),
      sofo(Knot.Knots, Knot),
      sofo(Knot.Clients, Knot.Client),
      sofo(Knot.Connectors, Knot.Client.Connector)
    ]
    Supervisor.start_link children, strategy: :one_for_one
  end
end
