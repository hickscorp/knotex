defmodule Knot.Logic.StateTest do
  use ExUnit.Case, async: true
  doctest Knot.Logic.State
  alias Knot.{Block, Hash, Logic.State}

  @node_uri "tcp://localhost:4001"

  setup_all :state

  describe "#genesis" do
    test "correctly answers", %{state: state} do
      {:ok, res} = state
        |> State.find("genesis")
      assert res == state.genesis
    end
  end

  describe "#head" do
    test "correctly answers", %{state: state} do
      {:ok, res} = state
        |> State.find("head")
      assert res == state.head
    end
  end

  describe "#ancestry" do
    test "responds with the top blocks when parameters are valid",
         %{state: state, ancestry: ancestry} do
      [_, b6, b5, b4, b3, b2, b1, _] = ancestry
      {:ok, res} = state
        |> State.ancestry(b6.hash)
      assert res == [b5, b4, b3, b2, b1]
    end

    test "honours the top argument", %{state: state} do
      Enum.each 1..10, fn (i) ->
        {:ok, res} = state
          |> State.ancestry(state.head.hash, i)
        assert length(res) == Enum.min([i, 7])
      end
    end

    test "correctly handles invalid parameters", %{state: state} do
      {:error, res} = state
        |> State.ancestry(Hash.invalid)
      assert res == :not_found
    end
  end

  defp state(ctx) do
    {:ok, genesis} = :knot
      |> Application.get_env(:genesis_data)
      |> Block.genesis
      |> Block.Store.store

    ancestry = Enum.reduce 1..7, [genesis], fn (_, [parent | _] = acc) ->
      height = parent.height + 1
      hash = Hash.perform to_string height
      {:ok, block} = hash
        |> Block.new(height)
        |> Map.put(:height, height)
        |> Map.put(:parent_hash, parent.hash)
        |> Map.put(:hash, hash)
        |> Block.seal
        |> Block.Store.store
      [block] ++ acc
    end

    state = @node_uri
      |> URI.parse
      |> State.new(genesis)
      |> Map.put(:head, hd(ancestry))

    {:ok, ctx |> Map.put(:state, state)
              |> Map.put(:ancestry, ancestry)}
  end
end
