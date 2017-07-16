defmodule ReflowProxy.Listener do
  #require Logger

  def start_link do
    opts = [port: 9000, max_connections: 10]
    {:ok, _} = :ranch.start_listener(:proxy_listener, 5, :ranch_tcp, opts, ReflowProxy.Handler, [])
  end

end