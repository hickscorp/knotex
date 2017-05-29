defmodule Knot.Mixfile do
  use Mix.Project

  @name     :knot
  @version  "0.1.0"

  def project do
    [
      app:              @name,
      version:          @version,
      elixir:           "~> 1.4",
      build_path:       "../../_build",
      config_path:      "../../config/config.exs",
      deps_path:        "../../deps",
      lockfile:         "../../mix.lock",
      build_embedded:   Mix.env == :prod,
      start_permanent:  Mix.env == :prod,
      elixirc_paths:    elixirc_paths(Mix.env),
      deps:             deps(Mix.env)
    ]
  end

  def application do
    [
      mod: {Knot.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps(:test) do
    [] ++ deps(:prod)
  end
  defp deps(:dev) do
    [] ++ deps(:prod)
  end
  defp deps(:prod) do
    [
      {:bertex,   "~> 1.2"}
    ]
  end
end
