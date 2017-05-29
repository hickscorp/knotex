defmodule Mix.Tasks.Knot.AssertComs do
  @moduledoc false
  use Mix.Task

  @shortdoc "Starts two nodes and makes sure they can communicate."

  @spec run(list(String.t)) :: :ok
  def run(_args) do
    Application.ensure_all_started :knot

    # Starts a node listening on local addresses, port 4001:
    pierre = Knot.start "tcp://0.0.0.0:4001"
    # Starts a node listening on local addresses, port 4002:
    gina = Knot.start "tcp://0.0.0.0:4002"
    # Connect Gina's node to Pierre's:
    Knot.Client.Connector.start pierre.uri, gina.logic

    :ok
  end
end
