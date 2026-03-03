defmodule ShimmiePhoenixWeb.PageControllerTest do
  use ShimmiePhoenixWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == "/post/list"
  end
end
