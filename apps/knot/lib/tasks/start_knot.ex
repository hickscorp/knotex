defmodule Mix.Tasks.Knot.StartKnot do
  @moduledoc """
  Provides an easy way to start a node.
  """
  use Mix.Task
  require Logger

  @shortdoc "Starts the node given a binding URI and a peer list."

  def run(args) do
    Application.ensure_all_started :blockade

    {[bind: bind, peers: peers], _, _} = args
      |> OptionParser.parse(strict: [bind: :string, peers: :string])

    %{logic: logic} = bind
      |> URI.parse
      |> Knot.start

    peers
      |> String.split(",")
      |> Enum.filter(&(&1 != "none"))
      |> Enum.each(fn (peer) ->
        peer
          |> URI.parse
          |> Knot.Client.Connector.start(logic)
      end)
  end
end
