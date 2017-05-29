defmodule Mix.Tasks.Block.EnsureSanity do
  @moduledoc false
  use Mix.Task

  @shortdoc "Ensures that the app can perform."

  @spec run(list(String.t)) :: :ok
  def run(_args) do
    Application.ensure_all_started :knot
    Knot.Block.Kit.ensure_sanity!

    :ok
  end
end
