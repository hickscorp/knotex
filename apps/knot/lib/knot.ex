defmodule Knot do
  @moduledoc """
  Supervises and manages a node.

  A node is composed of different parts:
  - A logic GenServer which coordinates everything.
  - A listener which role is to handle incoming connections and be the
    acceptor (see `Knot.Listener`).
  - A supervisor in charge of the client processes (See `Knot.Client`).
  """
  use Supervisor
  require Logger
  alias __MODULE__, as: Knot

  @type      t :: Via.t
  @type socket :: :gen_tcp.socket

  defmodule Handle do
    @moduledoc false
    @type t :: %Handle{
           uri: URI.t,
          node: Knot.t,
         logic: Logic.t,
      listener: Listener.t
    }
    defstruct [
           uri: nil,
          node: nil,
         logic: nil,
      listener: nil
    ]
  end

  # Public API.

  @spec start(URI.t | String.t) :: Handle.t
  def start(%URI{} = uri) do
    case Supervisor.start_child(Knot.Knots, [uri]) do
      {:ok, _} -> make_handle uri
      {:error, {:already_started, _}} -> make_handle uri
    end
  end
  def start(address) when is_binary address do
    address
      |> URI.parse
      |> start
  end

  @spec stop(URI.t | String.t) :: :ok
  def stop(%URI{} = uri) do
    [{pid, _}] = Registry.lookup(Via.registry(), Via.id(uri, "node"))
    Supervisor.terminate_child Knot.Knots, pid
  end
  def stop(%Handle{uri: uri}) do
    stop uri
  end
  def stop(address) when is_binary address do
    address
      |> URI.parse
      |> stop
  end

  @spec start_link(URI.t) :: {:ok, pid}
  def start_link(uri) do
    Supervisor.start_link Knot, uri, name: Via.node(uri)
  end

  # Supervisor callbacks.

  def init(uri) do
    children = [
      worker(Knot.Logic, [uri]),
      worker(Knot.Listener, [uri, Via.logic(uri)])
    ]
    supervise children, strategy: :one_for_one
  end

  # Implementation.

  defp make_handle(uri) do
    %Handle{uri: uri,
           node: Via.node(uri),
          logic: Via.logic(uri),
       listener: Via.listener(uri)}
  end
end
