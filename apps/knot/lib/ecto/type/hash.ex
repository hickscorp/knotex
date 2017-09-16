defmodule Ecto.Type.Hash do
  @behaviour Ecto.Type

  @spec type :: :string
  def type, do: :string

  @spec cast(binary) :: {:ok, String.t}
  def cast(val), do: {:ok, Knot.Hash.to_string val}

  @spec load(String.t) :: {:ok, binary}
  def load(val), do: {:ok, Knot.Hash.from_string val}

  @spec dump(String.t) :: {:ok, binary}
  def dump(val), do: {:ok, Knot.Hash.to_string val}
end
