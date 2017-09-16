defmodule Ecto.Type.Nonce do
  @behaviour Ecto.Type

  @spec type :: :integer
  def type, do: :integer

  @spec cast(Knot.Block.nonce) :: {:ok, integer}
  def cast(val) when is_integer(val), do: {:ok, val}

  @spec load(integer) :: {:ok, Knot.Block.nonce}
  def load(val) when is_integer(val), do: {:ok, val}

  @spec dump(Knot.Block.nonce) :: {:ok, integer}
  def dump(val) when is_integer(val), do: load val
end
