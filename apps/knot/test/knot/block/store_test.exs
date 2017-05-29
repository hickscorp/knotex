defmodule Knot.Block.StoreTest do
  use ExUnit.Case, async: false
  alias Knot.{Hash, Block, Block.Store}
  doctest Knot.Block.Store

  @block %Block{
    hash:           Hash.perform("a"),
    parent_hash:    Hash.perform("a"),
    component_hash: Hash.perform("a"),
    timestamp:      1
  }

  setup :clear

  describe "#start_link" do
    test "is running" do
      {:error, {:already_started, s}} = Store.start_link
      assert s != nil
    end
  end

  describe "#count" do
    setup :store_block

    test "counts blocks" do
      assert Store.count() == 1
    end
  end

  describe "#store" do
    setup :store_block

    test "stores blocks" do
      assert Store.count() == 1
    end

    test "returns the block", %{stored_block: sb} do
      assert sb == @block
    end
  end

  describe "#find_by_hash" do
    setup :store_block

    test "finds the block when it exists" do
        assert Store.find_by_hash(@block.hash) == {:ok, @block}
    end

    test "doesn't return a block when none is found" do
        block = Store.find_by_hash(Hash.zero)
        assert block == {:error, :not_found}
    end
  end

  describe "#find_by_hash_and_height" do
    setup :store_block

    test "finds the block when it exists" do
        block = Store.find_by_hash_and_height @block.hash, @block.height
        assert block == {:ok, @block}
    end

    test "doesn't return a block when none is found for that height" do
      block = Store.find_by_hash_and_height @block.hash, @block.height + 1
      assert block == {:error, :not_found}
    end

    test "doesn't return a block when none is found for that hash" do
      block = Store.find_by_hash_and_height Hash.zero, @block.height
      assert block == {:error, :not_found}
    end
  end

  describe "#clear" do
    setup :store_block

    test "removes all blocks" do
      Store.clear
      assert Store.count == 0
    end
  end

  describe "#remove" do
    setup :store_block

    test "deletes the block when it exists" do
      Store.remove @block
      block = Store.find_by_hash @block.hash
      assert block == {:error, :not_found}
    end
  end

  defp clear(ctx) do
    Store.clear
    {:ok, ctx}
  end

  defp store_block(ctx) do
    sb = Store.store @block
    {:ok, Map.put(ctx, :stored_block, sb)}
  end
end
