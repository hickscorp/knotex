defmodule Explorer do
  @moduledoc false

  def controller do
    quote do
      use Phoenix.Controller, namespace: Explorer
      import Plug.Conn
      import Explorer.Router.Helpers
      import Explorer.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/explorer/templates", namespace: Explorer
      use Phoenix.HTML
      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]
      import Explorer.Router.Helpers
      import Explorer.ErrorHelpers
      import Explorer.Gettext
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import Explorer.Gettext
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply __MODULE__, which, []
  end
end
