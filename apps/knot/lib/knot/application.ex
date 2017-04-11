defmodule Knot.Application do
  @moduledoc false

  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      worker(Registry, [:unique, Registry.Knot]),
      sofo_for(Knots, Knot),
      sofo_for(Knot.Clients, Knot.Client),
      sofo_for(Knot.Connectors, Knot.Client.Connector)
    ]

    Supervisor.start_link children,
                          strategy: :one_for_one,
                          name: Knot.Supervisor
  end

  defp sofo_for(name, mod) do
    supervisor SofoSupervisor, [name, mod], id: name
  end
end
