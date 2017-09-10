defmodule Mix.Tasks.Knot.AssertComs do
  @moduledoc false
  use Mix.Task

  @shortdoc "Starts two nodes and makes sure they can communicate."

  @spec run(list(String.t)) :: :ok
  def run(_args) do
    Application.ensure_all_started :knot

    genesis = :knot
      |> Application.get_env(:genesis_data)
      |> Knot.Block.genesis

    pierre = Knot.start "tcp://0.0.0.0:4001", genesis
    gina = Knot.start "tcp://0.0.0.0:4002", genesis

    Knot.Client.Connector.start pierre.uri, gina.logic

    :ok
  end
end
