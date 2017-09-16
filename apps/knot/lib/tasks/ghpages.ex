defmodule Mix.Tasks.Docs.Ghpages do
  use Mix.Task

  @moduledoc """
  A task for uploading documentation to gh-pages.
  """

  defp run!(command) do
    if Mix.shell.cmd(command) != 0 do
      raise Mix.Error, message: "command `#{command}` failed"
    end
    :ok
  end

  def run(_) do
    File.rm_rf "doc"
    Mix.Task.run "docs"
    # First figure out the git remote to use based on the
    # git remote here.
    git_remote = Map.get(
        Regex.named_captures(~r/\: (?<git>.*)/,
            to_string(:os.cmd 'git remote show -n upstream | grep "Push  URL"')),
            "git")
    Mix.shell.info "Git remote #{git_remote}"
    File.cd! "doc"
    run! "git init ."
    run! "git add ."
    run! "git commit -a -m \"Generates documentation.\""
    run! "git remote add upstream #{git_remote}"
    run! "git push upstream master:gh-pages --force"
  end
end
