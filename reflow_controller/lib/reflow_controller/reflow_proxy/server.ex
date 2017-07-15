defmodule ReflowProxy.Server do
    require Logger

  @doc """
  Starts accepting connections on the given `port`.
  """
  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port,
                      [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(ReflowProxy.TaskSupervisor, fn -> handle_req(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp handle_req(socket) do
    msg = socket |> read_line()

    case Poison.decode(msg) do

        {:ok, json} when is_map(json) -> 
            now = DateTime.utc_now() |> DateTime.to_iso8601()
            data =  Map.merge(json, %{date_time: now})
            if Application.get_env(:reflow_controller, :log_to_file) do
              
            end
            log_results(["#{data.date_time},#{data["temp"]}\n"])

            ReflowController.Web.Endpoint.broadcast! "oven:proxy", "oven_msg", data

        {:ok, not_obj} -> Logger.error "Invalid JSON Object cannot proxy: #{not_obj}"
        {:error, _, _} -> Logger.error "Invalid JSON cannot parse: #{msg}"
        {:error, _} -> Logger.error "Invalid JSON cannot parse: #{msg}"
    end

    handle_req(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end

defp log_results(results) do
    file_path = Application.get_env(:reflow_controller, :log_file_path)
    {:ok, file} = File.open(file_path, [:append])
    save_results(file, results)
    File.close(file)
end

defp save_results(file, []), do: :ok
defp save_results(file, [data|rest]) do
    IO.binwrite(file, data)
    save_results(file, rest)
end

end