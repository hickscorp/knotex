use Mix.Config

config :explorer,
  namespace: Explorer

config :explorer, Explorer.Endpoint,
  url: [host: "localhost"],
  secret_key_base:
    "xctjF8s5mPgVWNM2H61n55TSN2O2ZjyXneUFaGq/TipZWOm5hW/9qzLj/ji54CAS",
  render_errors: [view: Explorer.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Explorer.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# config :explorer, :generators,
#   context_app: :knot

import_config "#{Mix.env}.exs"
