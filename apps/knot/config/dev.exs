use Mix.Config

config :knot, Knot.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "knot_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
