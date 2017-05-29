defmodule Mix.Tasks.Block.EnsureSanity do
  @moduledoc false
  use Mix.Task

  @shortdoc "Ensures that the app can perform."

  def run(_args) do
    Application.ensure_all_started :block
    Block.Kit.ensure_sanity!
  end
end
