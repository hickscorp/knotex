defmodule Explorer.Router do
  @moduledoc false
  use Explorer, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  forward "/graphql",  Absinthe.Plug,
                       schema: Explorer.Schema
  forward "/graphiql", Absinthe.Plug.GraphiQL,
                       schema: Explorer.Schema

  scope "/api", Explorer do
    pipe_through :api
    scope "/blocks" do
      get "/:id/ancestry", BlockController, :ancestry
    end
    resources "/blocks", BlockController, only: ~w(show)a
  end

  scope "/", Explorer do
    pipe_through :browser
    get "/", PageController, :index
  end
end
