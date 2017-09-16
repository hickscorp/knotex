defmodule Mix.Tasks.Knot.Start do
  @moduledoc false
  use Mix.Task

  @shortdoc "Starts a node given a binding URI and an optional peer list."

  @spec run(list(String.t)) :: :ok
  def run(args) do
    Application.ensure_all_started :knot

    {bind, peers} = args
      |> OptionParser.parse(strict: [bind: :string, connect: :keep])
      |> parse_options

    genesis = :knot
      |> Application.get_env(:genesis_data)
      |> Knot.Block.genesis

    handle = Knot.start bind, genesis
    Enum.each peers, &Knot.Client.Connector.start(handle, &1)

    :ok
  end

  defp parse_options({args, _, _}) do
    pop_options args, {nil, []}
  end
  defp pop_options([], parsed) do
    parsed
  end
  defp pop_options([{:bind, bind} | tail], {_, peers}) do
    pop_options tail, {URI.parse(bind), peers}
  end
  defp pop_options([{:connect, peer} | tail], {bind, peers}) do
    pop_options tail, {bind, [URI.parse(peer) | peers]}
  end
end
