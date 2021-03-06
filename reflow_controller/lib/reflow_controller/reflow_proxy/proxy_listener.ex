defmodule ReflowProxyListener do
  require Logger

  @doc """
  Starts accepting connections on the given `port`.
  """
  def accept(port) do
    {:ok, socket} = Socket.TCP.listen(port, packet: :line, mode: :active)
    Logger.info "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    import Supervisor.Spec
    {:ok, client} = Socket.accept(socket, mode: :active)

    pid = 
      case ReflowProxyListener.Supervisor.start_handler(client) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end
      
    :ok = Socket.process(client, pid)
    loop_acceptor(socket)
  end

 
end