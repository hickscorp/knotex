defmodule Knot.LogicTest do
  use ExUnit.Case
  alias Knot.Logic
  doctest Logic
  require Logger

  describe "for message handling" do
    setup :logic

    test "allows to query its pid", %{logic: logic} do
      assert logic == GenServer.call(logic, :pid)
    end
  end

  # TODO: Spec :on_listener_terminating, :on_client_socket message,
  # :on_client_ready, :on_client_data and :on_client_closed messages.

  describe "#deserialize" do
    test "correctly de-serializes data" do
      data = {:foo, "bar"}
      assert Knot.Logic.deserialize(Bertex.encode data) == {:ok, data}
    end

    test "describes the error on failure" do
      err = {:error, %ArgumentError{message: "argument error"}}
      assert Knot.Logic.deserialize(:bad_data) == err
    end
  end

  describe "#on_client_data" do
    test "answers when pinged" do
      # TODO: Stub a client and test:
      #   Logic.on_client_data(%{uri: nil}, nil, {:ping, 1})
    end
  end

  describe "#process_block_query" do
    test "handles :genesis query" do
      res = Logic.process_block_query nil, nil, :genesis
      assert res == Block.genesis()
    end
    test "handles :highest query" do
      res = Logic.process_block_query nil, nil, :highest
      assert res == Block.new(<<1>>, 382_921_200)
    end
    test "handles :ancestry query when provided with a valid hash" do
      res = Logic.process_block_query nil, nil, {:ancestry, "invalid hash"}
      assert res == :ok
    end
    test "handles :ancestry query when provided with an invalid hash" do
      query = {:ancestry, Block.genesis().hash}
      res = Logic.process_block_query nil, nil, query
      assert res == :ok
    end
    test "returns an error when an invalid query is passed" do
      res = Logic.process_block_query nil, nil, {:invalid, "query"}
      assert res == {:error, :invalid_block_query}
    end
  end

  defp logic(ctx) do
    Logger.warn "A new logic server is being started."
    uri = URI.parse "tcp://localhost:4001"
    {:ok, logic} = Logic.start_link uri

    {:ok, Map.put(ctx, :logic, logic)}
  end
end
