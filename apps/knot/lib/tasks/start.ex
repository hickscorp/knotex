defmodule Mix.Tasks.Knot.Start do
  @moduledoc """
  A task used to start a node.

  Use it like this:

      mix knot.start --bind "tcp://0.0.0.0:4001" \\
                     --connect "tcp://10.0.0.1:4001" \\
                     --connect "tcp://10.0.0.2:4001"
  """

  use Mix.Task

  @spec run(list(String.t)) :: :ok
  def run(args) do
    Application.ensure_all_started :knot

    {bind, peers} = args
      |> OptionParser.parse(strict: [bind: :string, connect: :keep])
      |> parse_options

    handle = Knot.start bind, Knot.Block.application_genesis()
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
