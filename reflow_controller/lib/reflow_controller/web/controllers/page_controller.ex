defmodule ReflowController.Web.PageController do
  use ReflowController.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
