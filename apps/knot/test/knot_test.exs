defmodule Knot.Test do
  use ExUnit.Case
  doctest Knot

  @address "tcp://127.0.0.1:4001"

  test "doesn't start twice for the same URI" do
    uri = URI.parse @address
    genesis = Knot.Block.application_genesis()
    Knot.start uri, genesis
    {:error, {:already_started, pid}} = Supervisor.start_child Knot.Knots, [uri, genesis]
    assert Process.alive?(pid) == true
  end

  test "makes proper handles containing via tuples to all parts" do
    handle = Knot.make_handle @address
    uri = URI.parse @address
    assert        handle.uri == uri
    assert       handle.node == Knot.Via.node(uri)
    assert    handle.clients == Knot.Via.clients(uri)
    assert handle.connectors == Knot.Via.connectors(uri)
    assert      handle.logic == Knot.Via.logic(uri)
    assert   handle.listener == Knot.Via.listener(uri)
  end
end
