defmodule Explorer.ErrorHelpers do
  @moduledoc false
  use Phoenix.HTML

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn (error) ->
      content_tag :span, translate_error(error), class: "help-block"
    end)
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(Explorer.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(Explorer.Gettext, "errors", msg, opts)
    end
  end
end
