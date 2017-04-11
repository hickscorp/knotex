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
  alias __MODULE__, as: Knot

  @type      t :: Via.t | pid
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

  @spec start(URI.t) :: Handle.t
  def start(%URI{} = uri) do
    {:ok, _} = Supervisor.start_child Knots, [uri]

    %Handle{uri: uri,
           node: Via.node(uri),
          logic: Via.logic(uri),
       listener: Via.listener(uri)}
  end
  def start(uri) when is_binary uri do
    start URI.parse uri
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

  def blah do
    # In terminal 1:
    h1 = Knot.start URI.parse("tcp://127.0.0.1:4001")

    # In terminal 2:
    h2 = Knot.start URI.parse("tcp://127.0.0.1:4002")
    Knot.Client.Connector.start URI.parse("tcp://127.0.0.1:4001"), h2.logic
  end
end
