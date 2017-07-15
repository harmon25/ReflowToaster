defmodule ReflowController.Application do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(ReflowController.Web.Endpoint, []),
      # Start your own worker by calling: ReflowController.Worker.start_link(arg1, arg2, arg3)
      supervisor(Task.Supervisor, [[name: ReflowProxy.TaskSupervisor]]),
      worker(Task, [ReflowProxy.Server, :accept, [9000]]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ReflowController.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
