defmodule Explorer.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :explorer

  socket "/socket", Explorer.UserSocket

  plug Plug.Static,
    at: "/", from: :explorer, gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_explorer_key",
    signing_salt: "kUcEFCOv"

  plug Explorer.Router

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  @spec init(any, keyword) :: {:ok, keyword}
  def init(_key, config) do
    if config[:load_from_system_env] do
      port = System.get_env("PORT") ||
               raise "expected the PORT environment variable to be set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end
end
