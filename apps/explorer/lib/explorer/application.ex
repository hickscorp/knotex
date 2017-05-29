defmodule Explorer.Application do
  @moduledoc false
  use Application

  @spec start(any, any) :: {:ok, pid}
  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Explorer.Endpoint, [])
    ]

    opts = [strategy: :one_for_one, name: Explorer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec config_change(any, any, any) :: :ok
  def config_change(changed, _new, removed) do
    Explorer.Endpoint.config_change changed, removed
    :ok
  end
end
