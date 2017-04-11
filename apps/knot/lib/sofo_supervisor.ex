defmodule SofoSupervisor do
  @moduledoc """
  """
  use Supervisor
  require Logger
  alias __MODULE__, as: SofoSupervisor

  @type t :: Via.t | pid

  @spec start_link(Via.t, atom) :: {:ok, SofoSupervisor.t}
  def start_link(ref, mod) do
    Supervisor.start_link __MODULE__, mod, name: ref
  end

  @doc """
  Initializes a new simple one for one unbranded supervisor.
  """
  def init(mod) do
    children = [worker(mod, [], restart: :transient)]
    supervise children, strategy: :simple_one_for_one
  end
end
