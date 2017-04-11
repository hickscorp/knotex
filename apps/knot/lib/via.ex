defmodule Via do
  @moduledoc """
  Helps building `Registry` based process names.
  """
  alias __MODULE__, as: Via
  alias Knot.{Logic, Listener}

  @type id :: {String.t, pos_integer, String.t}
  @type  t :: {:via, Registry, {Registry.Knot, Via.id}}

  @doc """
  Transforms a URI into a displayable string.

  ## Examples

      iex> URI.parse("tcp://localhost:4001")
      iex>   |> Via.readable
      "localhost:4001"
  """
  @spec readable(URI.t) :: String.t
  def readable(uri), do: "#{uri.host}:#{inspect uri.port}"

  @doc """
  Builds a via-typle for a node given an URI.

  ## Examples

      iex> URI.parse("tcp://localhost:4001")
      iex>   |> Via.node
      {:via, Registry, {Registry.Knot, {"localhost", 4001, "node"}}}
  """
  @spec node(URI.t) :: Knot.t
  def node(uri), do: make uri, "node"

  @doc """
  Builds a via-typle for a node logic given an URI.

  ## Examples

      iex> URI.parse("tcp://localhost:4001")
      iex>   |> Via.logic
      {:via, Registry, {Registry.Knot, {"localhost", 4001, "logic"}}}
  """
  @spec logic(URI.t) :: Logic.t
  def logic(uri), do: make uri, "logic"

  @doc """
  Builds a via-typle for a node listener given an URI.

  ## Examples

      iex> URI.parse("tcp://localhost:4001")
      iex>   |> Via.listener
      {:via, Registry, {Registry.Knot, {"localhost", 4001, "listener"}}}
  """
  @spec listener(URI.t) :: Listener.t
  def listener(uri), do: make uri, "listener"


  @doc """
  Given an URI and a suffix, returns a via-tuple compatible with `Registry`.

  ## Examples

      iex> URI.parse("tcp://localhost:4001")
      iex>   |> Via.make("sup")
      {:via, Registry, {Registry.Knot, {"localhost", 4001, "sup"}}}
  """
  @spec make(URI.t, String.t) :: Via.t
  def make(uri, suffix) do
    uuid = id uri, suffix
    {:via, Registry, {Registry.Knot, uuid}}
  end

  @spec id(URI.t, String.t) :: id
  defp id(uri, suffix) do
    {uri.host, uri.port, suffix}
  end
end
