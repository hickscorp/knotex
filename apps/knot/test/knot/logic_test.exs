defmodule Knot.LogicTest do
  use ExUnit.Case, async: false
  doctest Knot.Logic
  require Logger
  alias Knot.Logic

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
      assert Logic.deserialize(Bertex.encode data) == {:ok, data}
    end

    test "describes the error on failure" do
      err = {:error, %ArgumentError{message: "argument error"}}
      assert Logic.deserialize(:bad_data) == err
    end
  end

  describe "#on_client_data" do
    test "answers when pinged" do
      # TODO: Stub a client and test:
      #   Logic.on_client_data(%{uri: nil}, nil, {:ping, 1})
    end
  end

  defp logic(ctx) do
    {:ok, logic} = "tcp://localhost:4001"
      |> URI.parse
      |> Logic.start_link
    {:ok, Map.put(ctx, :logic, logic)}
  end
end
