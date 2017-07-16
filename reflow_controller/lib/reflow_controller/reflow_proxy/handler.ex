
defmodule ReflowProxy.Handler do
    require Logger
    use GenServer

    def start_link(ref, socket, transport, opts) do
        pid = spawn_link(__MODULE__, :init, [ref, socket, transport, opts])
        {:ok, pid}
    end
         
    def init(ref, socket, transport, _Opts = []) do
        :ok = :ranch.accept_ack(ref)
        loop(socket, transport)
    end

    def loop(socket, transport) do

        case transport.recv(socket, 0, 2500) do
            {:ok, data} ->
                String.split(data, "\n") |> Enum.each(&handle_json(&1, socket))      
                loop(socket, transport)
            _ ->

                {ok, {oven_addr, _}} = :inet.peername(socket)
                Logger.warn "Connection with #{:inet.ntoa(oven_addr)} closed"
                ReflowProxy.remove_oven(oven_addr)
                :ok = transport.close(socket)
        end
    end

    defp handle_json("", _) do

    end

    defp handle_json(data, socket) do
       :timer.sleep(250)     
       case Poison.decode(data) do
        {:ok, json} when is_map(json) -> handle_message(socket, json)
        {:ok, not_obj} -> Logger.error "Invalid JSON Object cannot proxy: #{not_obj}"
        {:error, _, _} -> Logger.error "Invalid JSON cannot parse: #{data}"
        {:error, _} -> Logger.error "Invalid JSON cannot parse: #{data}"
      end
    end


    defp handle_message(socket, json) do
        {:ok, {oven_addr, _}} = :inet.peername(socket)
        ReflowProxy.add_oven(%{ip: oven_addr, socket: socket, reflowing: false})
        
        now = DateTime.utc_now() |> DateTime.to_iso8601()
        resp =  Map.merge(json, %{date_time: now})

        if Application.get_env(:reflow_controller, :log_to_file) do
            log_results(["#{resp.date_time},#{resp["temp"]}\n"])
        end

        ReflowController.Web.Endpoint.broadcast! "oven:proxy", "oven_msg", resp
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