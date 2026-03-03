defmodule ShimmiePhoenixWeb.Plugs.IPBan do
  @moduledoc false
  import Plug.Conn

  alias ShimmiePhoenix.Site.IPBans
  alias ShimmiePhoenix.Site.Users

  def init(opts), do: opts

  def call(conn, _opts) do
    actor = conn.assigns[:legacy_user] || Users.current_user(conn)
    remote_ip = Users.remote_ip_string(conn.remote_ip)

    case IPBans.evaluate_request(remote_ip, actor) do
      {:blocked, message_html} ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(403, message_html)
        |> halt()

      {:ok, effective_actor, nil} ->
        maybe_assign_actor(conn, effective_actor)

      {:ok, effective_actor, notice_html} ->
        conn
        |> maybe_assign_actor(effective_actor)
        |> assign(:ip_ban_notice_html, notice_html)
    end
  end

  defp maybe_assign_actor(conn, nil), do: conn
  defp maybe_assign_actor(conn, actor), do: assign(conn, :legacy_user, actor)
end
