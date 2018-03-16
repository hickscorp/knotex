use Mix.Config

config :knot, Knot.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "knot_prod",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
