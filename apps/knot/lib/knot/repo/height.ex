defmodule Knot.Repo.Type.Height do
  @behaviour Ecto.Type

  @spec type :: :integer
  def type, do: :integer

  @spec cast(Knot.Block.height) :: {:ok, integer}
  def cast(val) when is_integer(val), do: {:ok, val}

  @spec load(integer) :: {:ok, Knot.Block.height}
  def load(val) when is_integer(val), do: {:ok, val}

  @spec dump(Knot.Block.height) :: {:ok, integer}
  def dump(val) when is_integer(val), do: load val
end
