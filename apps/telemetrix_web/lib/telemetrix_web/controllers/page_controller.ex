defmodule TelemetrixWeb.PageController do
  use TelemetrixWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
