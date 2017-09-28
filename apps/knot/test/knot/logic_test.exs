defmodule Knot.LogicTest do
  use ExUnit.Case, async: false
  doctest Knot.Logic
  alias Knot.Logic

  setup_all :logic

  test "#pid returns the instance's pid", %{logic: logic} do
    assert logic == Logic.pid(logic)
  end

  test "#state returns the instance's state", %{logic: logic} do
    %Logic.State{genesis: genesis} = Logic.state(logic)
    assert genesis == Knot.Block.application_genesis()
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
    uri = URI.parse "tcp://localhost:4001"
    {:ok, logic} = Logic.start_link(uri, Knot.Block.application_genesis())
    {:ok, Map.put(ctx, :logic, logic)}
  end
end
