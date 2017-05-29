defmodule Explorer.ErrorViewTest do
  use Explorer.ConnCase, async: true
  import Phoenix.View

  test "renders 404.html" do
    assert render_to_string(Explorer.ErrorView, "404.html", []) ==
           "Resource not found"
  end

  test "render 500.html" do
    assert render_to_string(Explorer.ErrorView, "500.html", []) ==
           "Internal server error"
  end

  test "render any other" do
    assert render_to_string(Explorer.ErrorView, "505.html", []) ==
           "Internal server error"
  end
end
