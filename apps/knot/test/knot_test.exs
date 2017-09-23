defmodule Knot.Test do
  use ExUnit.Case
  doctest Knot

  test "doesn't start twice for the same URI" do
    uri = URI.parse "tcp://127.0.0.1:4001"
    genesis = Knot.Block.application_genesis()
    handle = Knot.start uri, genesis
    assert handle
  end
end
