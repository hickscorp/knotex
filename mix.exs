defmodule Knotex.Mixfile do
  @moduledoc false
  use Mix.Project

  @name     :knotex
  @version  "0.1.0"

  def project do
    [
      package:          package(),
      elixir:           "~> 1.4",
      apps_path:        "apps",
      build_embedded:   Mix.env == :prod,
      start_permanent:  Mix.env == :prod,
      deps:             [
        # Production dependencies.
        {:distillery,     "~> 1.5",  only: :prod},
        {:edeliver,       "~> 1.4",  only: :prod},
        # Dev / Tooling dependencies.
        {:ex_doc,         "~> 0.16", only: :dev},
        {:mix_test_watch, "~> 0.5",  only: :dev},
        {:credo,          "~> 0.8",  only: :dev},
        {:dialyxir,       "~> 0.5",  only: :dev}
      ],
      dialyzer:         [plt_add_deps: :app_tree, plt_add_apps: [:mix]]
    ]
  end

  defp package do
    [
      name:             @name,
      version:          @version,
      files:            ~w(config lib test mix.exs README*),
      maintainers:      ["Pierre Martin<HicksCorp@GMail.com>"],
      licenses:         ["Apache 2.0"],
      links:            %{"GitHub" => "https://github.com/hickscorp/knotex"}
    ]
  end
end
