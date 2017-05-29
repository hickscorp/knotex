defmodule Knot.Mixfile do
  use Mix.Project

  def project do
    [app: :knot,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(Mix.env),
     test_coverage: [tool: ExCoveralls],
     dialyzer: [plt_add_deps: :apps_direct, plt_add_apps: [:mix]]]
  end

  def application do
    [extra_applications: [:logger, :block],
     mod: {Knot.Application, []}]
  end

  defp deps(:test) do
    [] ++ deps(:prod)
  end
  defp deps(:dev) do
    [] ++ deps(:prod)
  end
  defp deps(:prod) do
    [{:block, in_umbrella: true},
     {:bertex, "~> 1.2.0"},
     {:socket, "~> 0.3.11"}]
  end
end
