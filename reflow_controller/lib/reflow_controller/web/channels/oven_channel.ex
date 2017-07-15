defmodule ReflowController.Web.OvenChannel do
    use Phoenix.Channel
   
    def join("oven:proxy", _auth_message, socket) do
        {:ok, socket}
    end


end
