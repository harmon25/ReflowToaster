defmodule ReflowProxy do
    use GenServer
    require Logger
    @initial_state []

    def start_link() do
        GenServer.start_link(__MODULE__, @initial_state, name: __MODULE__)
    end


    def handle_call(:stop_reflow, _from, state) do
        new_state = 
            Enum.map(state, fn(o)-> 
                %{o | reflowing: false}
            end)
        
        [resp] =  Enum.map(state, fn(o)-> 
                    send_msg(o.socket, %{cmd: "STOP_REFLOW"})
                end)
   
        {:reply, resp, new_state}
    end
    

    def handle_call({:stop_reflow, ip}, _from, state) do
        
        {new_state, resp} = 
            case Enum.find(state, nil, fn(o)-> o.ip == ip end) do
                nil -> 
                    Logger.error "No oven with that ip"
                    {state, {:error, "No oven with that ip"} }
                oven -> 
                    ovens = Enum.filter(state, fn(o)-> o.ip != oven.ip end)
                    resp = send_msg(oven.socket, %{cmd: "STOP_REFLOW"})
                    {[%{oven | reflowing: false} | ovens], resp}
            end

        {:reply, resp, new_state }
    end

    def handle_call(:start_reflow, _from, state) do
        new_state = 
            Enum.map(state, fn(o)->
                %{o | reflowing: true}
            end)

        [resp] =  Enum.map(state, fn(o)-> 
                    send_msg(o.socket, %{cmd: "START_REFLOW"})
                end)

        {:reply, resp ,new_state}
    end
    

    def handle_call({:start_reflow, ip}, state) do
        
         {new_state, resp} = 
            case Enum.find(state, nil, fn(o)-> o.ip == ip end) do
                nil -> 
                    Logger.error "No oven with that ip"
                    {state, {:error, "No oven with that ip"} }
                oven -> 
                    resp = send_msg(oven.socket, %{cmd: "START_REFLOW"})
                    ovens = Enum.filter(state, fn(o)-> o.ip != oven.ip end)
                   { [%{oven | reflowing: true} | ovens], resp}
            end

        {:reply, resp, new_state }
    end

    def handle_cast({:add_oven, new_oven}, state) do

        new_state =
            if Enum.any?(state, fn(o)-> o.ip == new_oven.ip end) do
               state
            else
               [new_oven | state]
            end
                
        {:noreply, new_state }
    end

    def handle_cast({:remove_oven, ip}, state) do

        new_state = 
            Enum.filter(state, fn(o)-> o.ip != ip end)
              
        {:noreply, new_state }
    end

    def handle_call(:get_ovens, _from, state) do
        {:reply, state, state }
    end

    def remove_oven(ip) do
        GenServer.cast(__MODULE__, {:remove_oven, ip})
    end

    def start_reflow() do
         GenServer.call(__MODULE__, :start_reflow)
    end

    def start_reflow(ip) do
        GenServer.call(__MODULE__, {:start_reflow, ip})
    end

    def stop_reflow() do
         GenServer.call(__MODULE__, :stop_reflow)
    end

    def stop_reflow(ip) do
        GenServer.call(__MODULE__, {:stop_reflow, ip})
    end

    def ovens() do
        GenServer.call(__MODULE__, :get_ovens)
    end

    def add_oven(oven) do
        GenServer.cast(__MODULE__, {:add_oven, oven})
    end



    defp send_msg(socket, msg) do
        json_msg = Poison.encode!(msg)
        :ranch_tcp.send(socket, to_charlist(json_msg))
        case :ranch_tcp.recv(socket, 0, 750) do
            {:ok, resp} -> Poison.decode(resp)
            {:error, _} -> nil
        end
    end



end