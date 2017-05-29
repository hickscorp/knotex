defmodule Blockade.Mixfile do
  use Mix.Project

  @app_name :blockade
  @version "0.1.0"

  def project do
    [elixir: "~> 1.4",
     version: @version,
     package: package(),
     apps_path: "apps",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(Mix.env),
     test_coverage: [tool: ExCoveralls],
     dialyzer: [plt_add_deps: :apps_direct, plt_add_apps: [:mix]]]
  end

  defp deps(:test) do
    [] ++ deps(:prod)
  end
  defp deps(:dev) do
    [{:ex_doc, "~> 0.14",        runtime: false},
     {:mix_test_watch, "~> 0.3", runtime: false},
     {:excoveralls, "~> 0.5",    runtime: false},
     {:dogma, "~> 0.1",          runtime: false},
     {:credo, "~> 0.4",          runtime: false},
     {:dialyxir, "~> 0.5",       runtime: false}] ++ deps(:prod)
  end
  defp deps(:prod) do
    [{:distillery, "~> 1.2"},
     {:edeliver, "~> 1.4.2"}]
  end

  defp package do
    [name: @app_name,
     files: ~w(config lib test mix.exs README*),
     maintainers: ["Pierre Martin>"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/hickscorp/blockade"}]
  end
end
