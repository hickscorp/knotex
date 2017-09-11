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

    bg = :knot
      |> Application.get_env(:genesis_data)
      |> Block.genesis
      |> Store.store

    block = Enum.reduce 1..128, bg, &make_block(&1, &2)

    case Hash.readable_short block.hash do
      "000096f0" -> Logger.info "All test passed."
               _ -> Logger.error "Unexpected hash."
    end

    :ok
  end

  @spec make_block(Block.timestamp, Block.t) :: Block.t
  defp make_block(offset, parent) do
    {:ok, block} = "Block #{offset}"
      |> Hash.perform
      |> Block.new(ref_timestamp(offset))
      |> Block.as_child_of(parent)
      |> Block.seal
      |> Miner.mine
      |> Store.store
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
