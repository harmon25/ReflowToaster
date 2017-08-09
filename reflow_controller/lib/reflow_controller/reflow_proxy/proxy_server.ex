
defmodule ReflowProxy.Server do
    require Logger
    use GenServer

    defmodule State do
        defstruct port: nil, sock: nil, request_count: 0
    end

    def start_link(sock) do
        GenServer.start_link(__MODULE__, sock, name: __MODULE__)
    end

    def init(sock) do
        {:ok, %State{sock: sock}}
    end


    def handle_cast(:read_temp, %State{sock: sock} = state) do
        msg = %{cmd_type: "READ_TEMP"} |> gen_message()
        sock = Socket.Stream.send!(sock, msg)
        {:noreply, %State{state | sock: sock} }
    end

    def handle_cast(:start_reflow, %State{sock: sock} = state) do
        msg = %{cmd_type: "START_REFLOW"} |> gen_message()
        sock = Socket.Stream.send!(sock, msg)
        {:noreply, %State{state | sock: sock} }
    end

    def handle_info(:timeout, %State{sock: sock} = state) do
        #Task.async(fn-> Socket.TCP.accept(sock) end)
        IO.puts "TIMEDOUT ERROR - remove oven"
        { :noreply, state }
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
            {:error, error} -> %{"err"=> true, "data"=> "JSON parsing error"}
        end
        |> oven_msg(state)
    end

    defp oven_msg(%{"msg_type"=> "HELLO", "data"=> ip} = msg_type, state) do
        IO.puts "HELLO MSG"
        ReflowProxy.add_oven(%{ip: ip, pid: self()})
        state
    end

    defp oven_msg(%{"msg_type"=> "OK"} = msg, state) do
        send(ReflowProxy, msg)
        state
    end

    defp oven_msg(%{"msg_type"=> "TEMP", "DATA"=> temp_c} = msg, state) do
        send(ReflowProxy, msg)
        state
    end

    defp oven_msg(%{"err"=> true, "data"=> err} = msg, state) do
        send(ReflowProxy, msg)
        state
    end

    defp oven_msg(msg, state) do
        IO.puts "OTHER MSG"
        IO.inspect msg
        state
    end

    defp gen_message(message) do
        Poison.encode!(message) <> "\n"
    end


end