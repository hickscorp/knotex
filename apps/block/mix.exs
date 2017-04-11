defmodule Block.Mixfile do
  use Mix.Project

  def project do
    [
      app: :block,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: [],
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_deps: :apps_direct, plt_add_apps: [:mix]]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Block.Application, []}
    ]
  end
end
