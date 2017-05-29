defmodule Explorer.Mixfile do
  use Mix.Project

  @name     :explorer
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
      compilers:        [:phoenix, :gettext] ++ Mix.compilers,
      deps:             deps(Mix.env())
    ]
  end

  def application do
    [
      mod: {Explorer.Application, []},
      extra_applications: [:logger, :runtime_tools, :absinthe_plug, :knot]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps(:test) do
    [] ++ deps(:prod)
  end
  defp deps(:dev) do
    [
      {:phoenix_live_reload,  "~> 1.0"},
    ] ++ deps(:prod)
  end
  defp deps(:prod) do
    [
      {:phoenix,          "~> 1.3"},
      {:phoenix_html,     "~> 2.10"},
      {:phoenix_pubsub,   "~> 1.0"},
      {:gettext,          "~> 0.11"},
      {:cowboy,           "~> 1.0"},
      {:absinthe_plug,    "~> 1.4.0-rc"},
      {:knot,             in_umbrella: true}
    ]
  end
end
