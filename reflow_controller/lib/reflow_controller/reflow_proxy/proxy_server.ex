
defmodule ReflowProxy.Server do
    require Logger
    use GenServer

    defmodule State do
        defstruct port: nil, sock: nil, request_count: 0, response: nil
    end

    def start_link(sock) do
        GenServer.start_link(__MODULE__, sock, name: __MODULE__)
    end

    def init(sock) do
        {:ok, %State{sock: sock}}
    end

    def handle_info(:timeout, %State{sock: sock} = state) do
        #Task.async(fn-> Socket.TCP.accept(sock) end)
        { :noreply, state }
    end

    def handle_cast(:read_temp, %State{sock: sock} = state) do
        cmd = %{cmd: "READ_TEMP"} |> Poison.encode!()
        sock = Socket.Stream.send!(sock, "#{cmd}\n")
        {:noreply, %State{state | sock: sock} }
    end

    def handle_info({ :tcp, socket, raw_data}, state) do
        state = parse_data(raw_data, state)
        { :noreply, %State{ state | sock: socket, request_count: state.request_count + 1 } } # inc?
    end

    def handle_info(args, state) do
        IO.puts "From here?"
        IO.inspect args
        { :noreply, state} # inc?
    end

    defp parse_data(raw_data, state) do
        Poison.decode(raw_data)
        |> case() do
            {:ok, json} -> json
            {:error, error} -> %{"ERROR"=> true, "DATA"=> "JSON parsing error"}
        end
        |> oven_msg(state)
    end

    defp oven_msg(%{"MSG"=> "HELLO", "DATA"=> ip} = msg, state) do
        IO.puts "HELLO MSG"
        ReflowProxy.add_oven(%{ip: ip, pid: self()})
        state
    end

    defp oven_msg(%{"MSG"=> "TEMP", "DATA"=> temp_c} = msg, state) do
        IO.puts "TEMP MSG"
        IO.inspect msg
        send(ReflowProxy, msg)
        %State{state | response: temp_c}
    end

    defp oven_msg(%{"ERROR"=> true} = msg, state) do
        IO.puts "ERROR MSG"
        IO.inspect msg
    end

    defp oven_msg(msg, state) do
        IO.puts "OTHER MSG"
        IO.inspect msg
        state
    end


end