defmodule Knot.Block.Kit do
  @moduledoc """
  Defines functions to help manage blocks manipulation.
  """
  require Logger
  alias Knot.{Hash, Block}
  alias Knot.Block.{Store, Miner}

  @doc """
  Ensures that all prerequisites for handling blocks are met and standard.

  It firsts retrieves the genesis block, and mines 128 blocks from it. Once the
  mining process is over, the result is compared to a known hash to ensure that
  the mining responds the same as any other computer.
  """
  @spec ensure_sanity! :: :ok
  def ensure_sanity! do
    Logger.info fn -> "Starting tests." end

    bg = Block.genesis
      |> Store.store
      |> ensure_valid!

    block = Enum.reduce 1..128, bg, &sanity_block_maker(&1, &2)

    case Hash.readable_short block.hash do
      "000096f0" -> Logger.info "All test passed."
               _ -> Logger.error "Unexpected hash."
    end

    :ok
  end

  @spec sanity_block_maker(Block.timestamp, Block.t) :: Block.t
  defp sanity_block_maker(offset, parent) do
    "Block #{offset}"
      |> Hash.perform
      |> Block.new(ref_timestamp(offset))
      |> Block.as_child_of(parent)
      |> Block.seal
      |> Miner.mine
      |> Store.store
      |> ensure_valid!
  end

  @spec ensure_valid!(Block.t) :: Block.t
  defp ensure_valid!(block) do
    Logger.info fn -> "Block: #{Hash.readable block.hash}@#{block.height}" end
    block
  end

  @spec ref_timestamp(non_neg_integer) :: Block.timestamp
  defp ref_timestamp(delta) do
    {:ok, dt, _} = DateTime.from_iso8601 "1982-02-18T23:00:00Z"
    dt
      |> DateTime.to_unix
      |> Kernel.+(delta)
  end
end
