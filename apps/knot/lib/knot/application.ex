defmodule Knot.Application do
  @moduledoc false

  use Application
  import Supervisor.Spec
  import SofoSupervisor.Spec

  def start(_type, _args) do
    children = [
      worker(Registry, [:unique, Via.registry()]),
      sofo(Knot.Knots, Knot),
      sofo(Knot.Clients, Knot.Client),
      sofo(Knot.Connectors, Knot.Client.Connector)
    ]
    Supervisor.start_link children, strategy: :one_for_one
  end
end
