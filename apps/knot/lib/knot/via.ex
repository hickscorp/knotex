defmodule Knot.Via do
  @moduledoc """
  Helps building `Registry` based process names.
  """
  alias __MODULE__, as: Via
  alias Knot.{Logic, Listener}

  @registry Knot.Registry

  @type              t :: {:via, Registry, {Knot.Registry, Via.id}}
  @type             id :: {String.t, pos_integer, String.t}
  @type uri_or_address :: URI.t | String.t

  @spec registry :: Knot.Registry
  def registry, do: @registry

  @doc """
  Transforms a URI into a displayable string.

  ## Examples

      iex> Knot.Via.to_string "tcp://localhost:4001"
      "localhost:4001"

      iex> "tcp://localhost:4001" |> URI.parse |> Knot.Via.to_string
      "localhost:4001"
  """
  @spec to_string(uri_or_address) :: String.t
  def to_string(uri_or_address) do
    uri = URI.parse uri_or_address
    "#{uri.host}:#{inspect uri.port}"
  end

  @doc """
  Builds a via-tuple for a node given an URI.

  ## Examples

      iex> Knot.Via.node "tcp://localhost:4001"
      {:via, Registry, {Knot.Registry, {"localhost", 4001, :node}}}
  """
  @spec node(uri_or_address) :: Knot.t
  def node(uri_or_address), do: make uri_or_address, :node

  @doc """
  Builds a via-tuple for a node clients supervisor given an URI.

  ## Examples

      iex> Knot.Via.clients "tcp://localhost:4001"
      {:via, Registry, {Knot.Registry, {"localhost", 4001, :clients}}}
  """
  @spec clients(uri_or_address) :: Knot.clients
  def clients(uri_or_address), do: make uri_or_address, :clients

  @doc """
  Builds a via-tuple for a node connectors supervisor given an URI.

  ## Examples

      iex> Knot.Via.connectors "tcp://localhost:4001"
      {:via, Registry, {Knot.Registry, {"localhost", 4001, :connectors}}}
  """
  @spec connectors(uri_or_address) :: Knot.connectors
  def connectors(uri_or_address), do: make uri_or_address, :connectors

  @doc """
  Builds a via-tuple for a node logic given an URI.

  ## Examples

      iex> Knot.Via.logic "tcp://localhost:4001"
      {:via, Registry, {Knot.Registry, {"localhost", 4001, :logic}}}
  """
  @spec logic(uri_or_address) :: Logic.t
  def logic(uri_or_address), do: make uri_or_address, :logic

  @doc """
  Builds a via-tuple for a node listener given an URI.

  ## Examples

      iex> Knot.Via.listener "tcp://localhost:4001"
      {:via, Registry, {Knot.Registry, {"localhost", 4001, :listener}}}
  """
  @spec listener(uri_or_address) :: Listener.t
  def listener(uri_or_address), do: make uri_or_address, :listener

  @doc """
  Given an URI and a suffix, returns a via-tuple compatible with `Registry`.

  ## Examples

      iex> Knot.Via.make "tcp://localhost:4001", :whatever
      {:via, Registry, {Knot.Registry, {"localhost", 4001, :whatever}}}

      iex> "tcp://localhost:4001" |> URI.parse |> Knot.Via.make(:whatever)
      {:via, Registry, {Knot.Registry, {"localhost", 4001, :whatever}}}
  """
  @spec make(uri_or_address, String.t) :: Via.t
  def make(uri_or_address, suffix) do
    uuid = id uri_or_address, suffix
    {:via, Registry, {@registry, uuid}}
  end

  @doc """
  Generates a per-uri unique ID that is suitable for via-tuple generation.

  ## Examples

      iex> Knot.Via.id "tcp://localhost:4001", :whatever
      {"localhost", 4001, :whatever}

      iex> "tcp://localhost:4001" |> URI.parse |> Knot.Via.id(:whatever)
      {"localhost", 4001, :whatever}
  """
  @spec id(uri_or_address, String.t) :: id
  def id(uri_or_address, suffix) do
    uri = URI.parse uri_or_address
    {uri.host, uri.port, suffix}
  end
end
