defmodule Knot.Repo.Type.Timestamp do
  @behaviour Ecto.Type

  @spec type :: :bigint
  def type, do: :bigint

  @spec cast(Knot.Block.timestamp) :: {:ok, integer}
  def cast(val) when is_integer(val), do: {:ok, val}

  @spec load(integer) :: {:ok, Knot.Block.timestamp}
  def load(val) when is_integer(val), do: {:ok, val}

  @spec dump(Knot.Block.timestamp) :: {:ok, integer}
  def dump(val) when is_integer(val), do: load val
end
