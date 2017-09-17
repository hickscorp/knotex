defmodule Mix.Tasks.Knot.AssertComs do
  @moduledoc false
  use Mix.Task
  require Logger

  @shortdoc "Starts two nodes and makes sure they can communicate."
  @node1_uri "tcp://0.0.0.0:4001"
  @node2_uri "tcp://0.0.0.0:4002"

  @spec run(list(String.t)) :: :ok | :error
  def run(_args) do
    Application.ensure_all_started :knot

    with %Knot.Block{} = gen <- Knot.Block.application_genesis(),
         %Knot.Handle{} = _node1 <- Knot.start(@node1_uri, gen),
         %Knot.Handle{} = node2  <- Knot.start(@node2_uri, gen),
         _ <- Knot.Client.Connector.start(node2, @node1_uri) do
      :ok
    else
      _ ->
        Logger.error fn ->
          "An error has occured while starting or connecting to a node."
        end
        :error
    end
  end
end
