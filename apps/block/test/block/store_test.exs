defmodule BlockStoreTest do
  use ExUnit.Case, async: false
  alias Block.Store
  doctest Block.Store

  @block %Block{
    hash:           Hash.perform("a"),
    parent_hash:    Hash.perform("a"),
    component_hash: Hash.perform("a")
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
      @block.hash
        |> Store.find_by_hash
        |> Kernel.==({:ok, @block})
        |> assert
    end

    test "doesn't return a block when none is found" do
      Hash.zero
        |> Store.find_by_hash
        |> Kernel.==({:error, :not_found})
        |> assert
    end
  end

  describe "#find_by_height_and_hash" do
    setup :store_block

    test "finds the block when it exists" do
      @block.height
        |> Store.find_by_height_and_hash(@block.hash)
        |> Kernel.==({:ok, @block})
        |> assert
    end

    test "doesn't return a block when none is found for that height" do
      @block.height
        |> Kernel.+(1)
        |> Store.find_by_height_and_hash(@block.hash)
        |> Kernel.==({:error, :not_found})
        |> assert
    end

    test "doesn't return a block when none is found for that hash" do
      @block.height
        |> Store.find_by_height_and_hash(Hash.zero)
        |> Kernel.==({:error, :not_found})
        |> assert
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
      @block.hash
        |> Store.find_by_hash
        |> Kernel.==({:error, :not_found})
        |> assert
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
