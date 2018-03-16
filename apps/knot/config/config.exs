use Mix.Config

config :knot, ecto_repos: [Knot.Repo]

import_config "#{Mix.env()}.exs"
