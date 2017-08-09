defmodule ReflowProxy do
    use GenServer
    require Logger
    alias ReflowController.Command

    defmodule Oven do
        defstruct ip: nil, pid: nil, reflowing: false, temp: nil
    end

    @initial_state []

    def start_link() do
        GenServer.start_link(__MODULE__, @initial_state, name: __MODULE__)
    end

   def handle_call(:read_temp, _from, state) do
       [oven] = state
       GenServer.cast(oven.pid, :read_temp)
       resp = receive_resp()
       {:reply, resp, [%Oven{oven | temp: resp}]}
   end

    def handle_call(:start_reflow, _from, state) do
        [oven] = state
        GenServer.cast(oven.pid, :start_reflow)
        resp = receive_resp()
       {:reply, resp, [%Oven{oven | reflowing: true}]}
   end

   def handle_cast(:stop_reflow, state) do
        new_state = Enum.map(state, fn(o)-> 
        GenServer.cast(o.pid, :start_reflow)
            %Oven{o | reflowing: false} end)
       {:noreply, new_state }
   end

   def handle_cast({:reflow_msg, temp}, state) do
        IO.inspect temp
       {:noreply, state }
   end


   def receive_resp() do
        receive do
            %{"cmd_msg"=> "STOP_REFLOW", "resp"=> "OK"} = msg -> 
                GenServer.cast(self(), :stop_reflow)
                :ok
            %{"msg_type"=> "TEMP", "DATA"=> temp} = msg ->         
                temp
            msg ->
                msg
 
        end
   end

    def handle_cast({:add_oven, new_oven}, state) do
        oven = %Oven{}   
        new_state = Enum.reject(state , fn(o)-> o.ip == new_oven.ip end)        
        {:noreply, [Map.merge(oven, new_oven) | new_state] }
    end

    def handle_cast({:remove_oven, ip}, state) do
        new_state = Enum.filter(state, fn(o)-> o.ip != ip end)
              
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

    def read_temp() do
         GenServer.call(__MODULE__, :read_temp)
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
end