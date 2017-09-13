defmodule Knot.Hash do
  @moduledoc """
  Defines helper functions around hashing.
  """
  @type t :: binary

  @invalid  :binary.copy <<0xff>>, 32
  @zero     :binary.copy <<0x00>>, 32

  @doc """
  Represents a completelly zero-filled hash.

  As this hash is very unlikelly to
  ever be found under current computational power availabilities, the zero-hash
  is often used as the top-level parent for any given chain.

  ## Examples

      iex> Knot.Hash.zero
      iex>   |> Base.encode16(case: :lower)
      "0000000000000000000000000000000000000000000000000000000000000000"
  """
  @spec zero :: t
  def zero, do: @zero

  @doc """
  Represents an invalid hash that can be used for temporary constructs.

  ## Examples

      iex> Knot.Hash.invalid
      iex>   |> Base.encode16(case: :lower)
      "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
  """
  @spec invalid :: t
  def invalid, do: @invalid

  @doc """
  Performs hashing on a given binary using the SHA-256 algorithm.

  ## Examples

      iex> "a"
      iex>   |> Knot.Hash.perform
      iex>   |> Base.encode16(case: :lower)
      "ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb"
  """
  @spec perform(binary | list) :: t
  def perform(data) when is_binary data do
    :crypto.hash :sha256, data
  end
  def perform(data) when is_list data do
    data
      |> Enum.join
      |> perform
  end

  @doc """
  Transforms a hash into a readable string form.

  ## Examples

      iex> :binary.copy(<<0x0f>>, 32)
      iex>   |> Knot.Hash.to_string
      "0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f"

      iex> :binary.copy(<<0x0f>>, 32)
      iex>   |> Knot.Hash.to_string(case: :upper)
      "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"

      iex> :binary.copy(<<0x0f>>, 32)
      iex>   |> Knot.Hash.to_string(short: true)
      "0f0f0f0f"

      iex> :binary.copy(<<0x0f>>, 32)
      iex>   |> Knot.Hash.to_string(case: :upper, short: true)
      "0F0F0F0F"
  """
  @spec to_string(t, keyword) :: String.t
  def to_string(hash, opts \\ [])
  def to_string(nil, _), do: "!NIL!"
  def to_string(hash, opts) when is_binary(hash) and byte_size(hash) == 32 do
    c = Keyword.get opts, :case, :lower
    ret = Base.encode16 hash, case: c
    case Keyword.get opts, :short, false do
      false -> ret
       true -> String.slice ret, 0..7
    end
  end

  @doc """
  Transforms a string into a hash by first downcasing it.

  ## Examples

      iex> "e18470da40760a375193f01c8e5212c9a7487505bef190b8623d73bff010fffa"
      iex>   |> Knot.Hash.from_string
      iex>   |> Knot.Hash.to_string(short: true)
      "e18470da"
  """
  @spec from_string(String.t) :: Hash.t
  def from_string(str) do
    str
      |> String.downcase
      |> Base.decode16!(case: :lower)
  end

  @doc """
  Checks whether a hash matches a given difficulty or not.

  ## Examples

      # A difficulty of 1 requires at least 1 leading zero.
      iex> Knot.Hash.ensure_hardness <<0x01, 0x01>>, 1
      {:error, :unmet_difficulty}

      # A difficulty of 1 requires at least 1 leading zero.
      iex> Knot.Hash.ensure_hardness <<0x00, 0x01>>, 1
      :ok
  """
  @spec ensure_hardness(t, Block.difficulty)
                       :: :ok | {:error, :unmet_difficulty}
  def ensure_hardness(_, 0), do: :ok
  def ensure_hardness(<<f::size(8), _::binary>>, _) when f != 0 do
    {:error, :unmet_difficulty}
  end
  def ensure_hardness(<<0::size(8), rest::binary>>, r) when r > 0 do
    ensure_hardness rest, r - 1
  end
end
