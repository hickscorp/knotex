defmodule Explorer.ErrorView do
  @moduledoc false
  use Explorer, :view

  @spec render(String.t, map) :: map
  def render("error.json", %{message: message}), do: %{error: message}
  def render("404.html", _assigns), do: "Resource not found"
  def render("500.html", _assigns), do: "Internal server error"

  def template_not_found(_template, assigns), do: render "500.html", assigns
end
