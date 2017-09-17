defmodule Mix.Tasks.Knot.EnsureSanity do
  @moduledoc """
  A task used to verify the runtime environment.

  Use it like this:

      mix knot.ensure_sanity

  You should then see a bunch of hashes. Those are in fact blocks being mined
  using a very low difficulty. After mining 128 blocks on top of the genesis
  sample block, you should see a message saying something like this:

      20:41:46.889 [info]  All test passed.

  This means that the 129th block in the chain has the expected properties and
  fields, and a node running on this machine would behave correctly.
  """

  use Mix.Task
  require Logger
  alias Knot.{Hash, Block, Block.Miner}

  @spec run(list(String.t)) :: :ok
  def run(_args) do
    Application.ensure_all_started :knot

    Logger.info fn -> "Starting tests." end

    {:ok, bg} = Block.store Knot.Block.application_genesis()
    head = Enum.reduce 1..128, bg, &make_block(&1, &2)

    case Hash.to_string head.hash, short: true do
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
      |> Block.store
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
