defmodule Knot do
  @moduledoc """
  Supervises and manages a node.

  A node is composed of different parts:
  - Two simple one-for-one supervisors. One for the connectors and one for
    the clients.
  - A logic process which coordinates everything (See `Knot.Logic`).
  - A listener which role is to handle incoming connections and be the
    acceptor (see `Knot.Listener`).
  - A supervisor in charge of the client processes (See `Knot.Client`).
  """

  use Supervisor
  alias __MODULE__, as: Knot
  alias Knot.Via
  import Knot.SofoSupervisor.Spec

  @type          t :: Via.t
  @type     socket :: :gen_tcp.socket
  @type    clients :: Via.t | pid
  @type connectors :: Via.t | pid

  defmodule Handle do
    @moduledoc false
    @typedoc "Represent a running node handle."
    @type t :: %Handle{
             uri: URI.t,
            node: Knot.t,
         clients: Knot.clients,
      connectors: Knot.connectors,
           logic: Logic.t,
        listener: Listener.t
    }
    defstruct [
             uri: nil,
            node: nil,
         clients: nil,
      connectors: nil,
           logic: nil,
        listener: nil
    ]
  end

  # Public API.

  @spec start(Via.uri_or_address, Block.t) :: Handle.t
  def start(uri_or_address, block) do
    case Supervisor.start_child Knot.Knots, [uri_or_address, block] do
      {:ok, _}                        -> make_handle uri_or_address
      {:error, {:already_started, _}} -> make_handle uri_or_address
    end
  end

  @spec stop(Via.uri_or_address | Handle.t) :: :ok
  def stop(%Handle{uri: uri}) do
    stop uri
  end
  def stop(uri_or_address) do
    [{pid, _}] = Registry.lookup Via.registry(), Via.node(uri_or_address)
    Supervisor.terminate_child Knot.Knots, pid
  end

  @spec start_link(Via.uri_or_address, Block.t) :: {:ok, pid}
  def start_link(uri_or_address, block) do
    Supervisor.start_link Knot, {uri_or_address, block}, name: Via.node(uri_or_address)
  end

  # Supervisor callbacks.

  @spec init({Via.uri_or_address, Block.t}) :: {:ok, {:supervisor.sup_flags, [:supervisor.child_spec]}}
  def init({uri_or_address, genesis}) do
    uri = URI.parse uri_or_address
    children = [
      sofo(Via.clients(uri), Knot.Client),
      sofo(Via.connectors(uri), Knot.Client.Connector),
      worker(Knot.Logic, [uri, genesis]),
      worker(Knot.Listener, [uri])
    ]
    supervise children, strategy: :one_for_one
  end

  # Implementation.

  @spec make_handle(Via.uri_or_address) :: Handle.t
  def make_handle(uri_or_address) do
    uri = URI.parse uri_or_address
    %Handle{uri: uri,
            node: Via.node(uri),
         clients: Via.clients(uri),
      connectors: Via.connectors(uri),
           logic: Via.logic(uri),
        listener: Via.listener(uri)}
  end
end
