defmodule Mix.Tasks.Docs.Ghpages do
  @moduledoc """
  A task for generating and uploading documentation to github pages.

  Run it by issuing `mix docs.ghpages`.
  """

  use Mix.Task

  defp exec!(command) do
    if Mix.shell.cmd(command) != 0 do
      raise Mix.Error, message: "command `#{command}` failed"
    end
    :ok
  end

  def run(_) do
    # First figure out the git remote to use based on the
    # git remote here.
    remote = Map.get(
        Regex.named_captures(
          ~r/\: (?<git>.*)/,
          to_string(:os.cmd 'git remote show -n upstream | grep "Push  URL"')
        ),
        "git"
    )

    File.rm_rf "doc"
    Mix.Task.run "docs"
    File.cd! "doc"
    exec! "git init .; git add .; git commit -a -m \"Generates documentation.\""
    exec! "git remote add upstream #{remote}"
    exec! "git push -f upstream master:gh-pages"
  end
end
