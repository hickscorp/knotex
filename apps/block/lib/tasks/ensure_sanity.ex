defmodule Mix.Tasks.Block.EnsureSanity do
  @moduledoc """
  Provides sanity verifications as a mix task.
  """
  use Mix.Task

  @shortdoc "Ensures that the app can perform."

  def run(_args) do
    Application.ensure_all_started :block
    Block.Kit.ensure_sanity!
  end
end
