defmodule Knot.ViaTest do
  use ExUnit.Case, async: true
  doctest Knot.Via
  alias Knot.Via

  @address "tcp://127.0.0.1:4001"

  test "can be convert to a readable string" do
    assert Via.to_string(@address) == "127.0.0.1:4001"
  end

  Enum.each ~w(node clients connectors logic listener)a, fn (type) ->
    test "can make a proper #{type} via tuple" do
      type = unquote(type)
      tupple = {:via, Registry, {Knot.Registry, {"127.0.0.1", 4001, type}}}
      assert Kernel.apply(Knot.Via, type, [@address]) == tupple
    end
  end

  test "can make generic tuples using the #make function" do
    expectation = {:via, Registry, {Knot.Registry, {"127.0.0.1", 4001, :suffix}}}
    assert Via.make(@address, :suffix) == expectation
  end

  test "can generate ids using the #id function" do
    expectation = {"127.0.0.1", 4001, :suffix}
    assert Via.id(@address, :suffix) == expectation
  end
end
