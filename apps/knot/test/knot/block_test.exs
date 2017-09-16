defmodule Knot.BlockTest do
  use ExUnit.Case, async: false
  doctest Knot.Block
  alias Knot.{Block, Hash}

  setup_all :genesis
  setup ~w(reset_store mined_block)a

  @content "Main test block."

  describe "#new" do
    setup :new_block

    test "sets the timestamp", %{block: b} do
      assert b.timestamp == now()
    end

    test "sets the content hash", %{block: b} do
      assert b.content_hash == Hash.perform @content
    end
  end

  describe "#as_child_of" do
    setup ~w(new_block new_child_block)a

    test "increases height by 1", %{block: b, child: c} do
      assert c.height == b.height + 1
    end

    test "sets the parent hash", %{block: b, child: c} do
      assert c.parent_hash == b.hash
    end
  end

  describe "#genesis" do
    setup :genesis

    test "has its content hash set", %{genesis: genesis} do
      hash = Hash.perform "Unspendable block."
      assert genesis.content_hash == hash
    end

    test "has a nonce", %{genesis: genesis} do
      assert genesis.nonce == 3_492_211
    end

    test "has a correct hash et", %{genesis: genesis} do
      assert "0000007b" == Hash.to_string(genesis.hash, short: true)
    end
  end

  describe "#ensure_mined" do
    setup ~w(mined_block mined_block_with_invalid_parent)a

    test "is successful when a block was mined and its parent is known", ctx do
      ret = ctx.mined_block
        |> Block.ensure_mined
      assert ret == :ok
    end

    test "fails when the block isn't finalized", ctx do
      ret = %{ctx.mined_block | nonce: 0}
        |> Block.ensure_mined
      assert ret == {:error, :hash_mismatch}
    end

    test "is false when the block's parent is unknown", ctx do
      ret = ctx.mined_block_with_invalid_parent
        |> Block.ensure_mined
      assert ret == {:error, :unknown_parent}
    end
  end

  describe "#ancestry" do
    setup ~w(mined_block store_mined_block_and_mine_child)a

    test "errors when the block's parent is unknown", ctx do
      ancestry = Block.ancestry %{ctx.mined_block | parent_hash: Hash.invalid()}
      assert ancestry == {:error, :not_found}
    end

    test "returns an array containing all parents", ctx do
      {:ok, ancestry} = Block.ancestry ctx.mined_block
      ancestry_hashes = Enum.map ancestry, &(&1.hash)
      assert ancestry_hashes == [ctx.genesis.hash]
    end

    test "returns the parents in the correct order", ctx do
      {:ok, ancestry} = Block.ancestry ctx.mined_child
      ancestry_hashes = Enum.map ancestry, &(&1.hash)
      assert ancestry_hashes == [ctx.mined_block.hash, ctx.genesis.hash]
    end
  end

  describe "#ensure_known_parent" do
    setup ~w(mined_block mined_block_with_invalid_parent)a

    test "succeeds for a block with a known parent", ctx do
      res = Block.ensure_known_parent ctx.mined_block
      assert res == :ok
    end

    test "fails for a block with an unknown parent", ctx do
      res = ctx.mined_block_with_invalid_parent
        |> Block.ensure_known_parent
      assert res == {:error, :unknown_parent}
    end
  end

  describe "#ancestry_contains?" do
    setup ~w(mined_block store_mined_block_and_mine_child)a

    test "is false if the hash isn't part of the block's ancestry", ctx do
      ctx.genesis
        |> Block.ancestry_contains?(ctx.mined_block)
        |> refute
    end

    test "is false if the hash isn't even known", ctx do
      ctx.genesis
        |> Block.ancestry_contains?(ctx.genesis.content_hash)
        |> refute
    end

    test "is true if the argument is the block's parent", ctx do
      ctx.mined_block
        |> Block.ancestry_contains?(ctx.genesis)
        |> assert
    end

    test "is true if the argument is the block's grandpa", ctx do
      ctx.mined_child
        |> Block.ancestry_contains?(ctx.genesis)
        |> assert
    end

    test "also works with a hash", ctx do
      ctx.mined_child
        |> Block.ancestry_contains?(ctx.genesis.hash)
        |> assert
    end
  end

  describe "#difficulty" do
    test "is 1 up to the first tier" do
      for n <- 0..127 do
        diff = Block.difficulty n
        assert diff == 1
      end
    end

    test "is 2 up to the first tier" do
      for n <- 128..255 do
        diff = Block.difficulty n
        assert diff == 2
      end
    end
  end

  defp now do
    DateTime.from_iso8601 "1982-02-18T23:01:07Z"
  end

  defp new_block(ctx) do
    block = @content
      |> Hash.perform
      |> Block.new(now())
    {:ok, Map.put(ctx, :block, block)}
  end

  defp new_child_block(%{block: block} = ctx) do
    child = "Child test block."
      |> Hash.perform
      |> Block.new(now())
      |> Block.as_child_of(block)
    {:ok, Map.put(ctx, :child, child)}
  end

  defp genesis(ctx) do
    block = :knot
      |> Application.get_env(:genesis_data)
      |> Block.genesis
    {:ok, Map.put(ctx, :genesis, block)}
  end

  defp reset_store(%{genesis: genesis} = ctx) do
    Block.clear
    Block.store genesis
    {:ok, Map.put(ctx, :genesis, genesis)}
  end

  defp mined_block(ctx) do
    block = %Block{
      component_hash: Hash.from_string(
        "e18470da40760a375193f01c8e5212c9a7487505bef190b8623d73bff010fffa"),
      content_hash: Hash.from_string(
        "e106f30b764506ee0e5304d30921b42335b753b174af1db2c921ab77b6a3ec61"),
      parent_hash: Hash.from_string(
        "0000007b5786c03293981d893c65da1193123c9367a1fddc56cd8a3658a93470"),
      hash: Hash.from_string(
        "001c33c119a22722ffc4f814751761db5e9ab172ad883e3f4f34b827305aa87d"),
      height: 1,
      nonce: 124,
      timestamp: 19_820_218
    }

    {:ok, Map.put(ctx, :mined_block, block)}
  end

  def mined_block_with_invalid_parent(ctx) do
    block = %{ctx.mined_block |
      parent_hash: Hash.invalid(),
      hash: Hash.from_string(
        "001c33c119a22722ffc4f814751761db5e9ab172ad883e3f4f34b827305aa87d"
      )
    }
    {:ok, Map.put(ctx, :mined_block_with_invalid_parent, block)}
  end

  defp store_mined_block_and_mine_child(ctx) do
    Block.store ctx.mined_block

    mined_child = %Block{
      component_hash: Hash.from_string(
        "50a259ce826e6feb1f24945800c965489e65d7c919ad348cfdff88232d6bd7cb"),
      content_hash: Hash.from_string(
        "2aaaec34732555a3ab420e4c2744d2a45a3f3502d65866d49a7126edd8363790"),
      parent_hash: Hash.from_string(
        "001c33c119a22722ffc4f814751761db5e9ab172ad883e3f4f34b827305aa87d"),
      hash: Hash.from_string(
        "00dee94f2edf27ccf49cbc6636749cdbdfa8e7e8933a39d0be3f75dfd906f99e"),
      height: 2,
      nonce: 11,
      timestamp: 19_820_219
    }

    {:ok, Map.put(ctx, :mined_child, mined_child)}
  end
end
