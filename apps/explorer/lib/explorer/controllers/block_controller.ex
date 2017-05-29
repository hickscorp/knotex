defmodule Explorer.BlockController do
  @moduledoc false
  use Explorer, :controller

  action_fallback Explorer.FallbackController

  plug :fetch_block
  plug :assign_top when action == :ancestry
  plug :fetch_blocks when action == :ancestry

  @spec show(Conn.t, %{}) :: Conn.t
  def show(conn, _params) do
    render conn, :show, block: conn.assigns[:block]
  end

  @spec ancestry(Conn.t, %{}) :: Conn.t
  def ancestry(conn, _params) do
    render conn, :ancestry, blocks: conn.assigns[:blocks]
  end

  @spec fetch_block(Conn.t, any) :: Conn.t
  defp fetch_block(%{params: %{"id" => id}} = conn, _opts) do
    case Explorer.BlockResolver.find %{id: id}, nil do
      {:ok, block} -> assign conn, :block, block
               err -> halt_over_error conn, err
    end
  end

  @spec assign_top(Conn.t, any) :: Conn.t
  def assign_top(%{params: params} = conn, _opts) do
    params
      |> Map.get("top", "5")
      |> String.to_integer
      |> Kernel.abs
      |> reverse_assign(conn, :top)
  end

  @spec fetch_blocks(Conn.t, any) :: Conn.t
  defp fetch_blocks(%{assigns: assigns} = conn, _opts) do
    case Explorer.BlockResolver.ancestry assigns, nil do
      {:ok, blocks} -> assign conn, :blocks, blocks
                err -> halt_over_error conn, err
    end
  end

  @spec halt_over_error(Conn.t, {:error, atom}) :: Conn.t
  defp halt_over_error(conn, err) do
    {status, message} = case err do
      {:error, :not_found} ->
        {:not_found, "Resource Not Found"}
      {:error, :badarg} ->
        {:unprocessable_entry, "Bad argument"}
    end

    conn
      |> put_status(status)
      |> assign(:message, message)
      |> render(Explorer.ErrorView, "error.json", %{})
      |> halt
  end

  @spec reverse_assign(any, Conn.t, atom) :: Conn.t
  defp reverse_assign(val, conn, key) do
    assign conn, key, val
  end
end
