defmodule ShimmiePhoenixWeb.LegacyFallbackController do
  use ShimmiePhoenixWeb, :controller

  def show(conn, _params) do
    conn
    |> assign(:page_title, "Legacy Route Online")
    |> render(:show, path: conn.request_path)
  end
end
