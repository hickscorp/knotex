defmodule Explorer.UserSocket do
  @moduledoc false
  use Phoenix.Socket

  transport :websocket, Phoenix.Transports.WebSocket

  def connect(_params, socket), do: {:ok, socket}
  def id(_socket), do: nil
end
