defmodule ReflowProxyListener.Supervisor do
  use Supervisor

  # A simple module attribute that stores the supervisor name

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_handler(sock) do
    Supervisor.start_child(ReflowProxyListener.Supervisor, [sock])
  end

  def init(:ok) do
    children = [
      worker(ReflowProxy.Server, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end