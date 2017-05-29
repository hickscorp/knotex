defmodule Explorer.PageController do
  @moduledoc false
  use Explorer, :controller

  @spec index(Conn.t, map) :: Conn.t
  def index(conn, _params) do
    render conn, "index.html"
  end
end
