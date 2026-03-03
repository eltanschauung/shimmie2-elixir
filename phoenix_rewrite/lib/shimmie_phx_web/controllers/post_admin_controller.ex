defmodule ShimmiePhoenixWeb.PostAdminController do
  use ShimmiePhoenixWeb, :controller

  alias ShimmiePhoenix.Site.PostAdmin
  alias ShimmiePhoenix.Site.Users

  def feature(conn, params) do
    with {:ok, image_id} <- parse_image_id(params),
         :ok <- PostAdmin.feature(image_id, current_user(conn)) do
      redirect(conn, to: "/post/view/#{image_id}")
    else
      {:error, :permission_denied} -> send_resp(conn, 403, "Permission Denied")
      {:error, :post_not_found} -> send_resp(conn, 404, "Not Found")
      {:error, _} -> send_resp(conn, 500, "Featured Update Failed")
    end
  end

  def regen_thumb(conn, params) do
    with {:ok, image_id} <- parse_image_id(params),
         :ok <- PostAdmin.regenerate_thumb(image_id, current_user(conn)) do
      redirect(conn, to: "/post/view/#{image_id}")
    else
      {:error, :permission_denied} ->
        send_resp(conn, 403, "Permission Denied")

      {:error, :post_not_found} ->
        send_resp(conn, 404, "Not Found")

      {:error, :unsupported_media} ->
        redirect(conn, to: "/post/view/#{image_id_from_params(params)}")

      {:error, _} ->
        redirect(conn, to: "/post/view/#{image_id_from_params(params)}")
    end
  end

  def delete_image(conn, params) do
    with {:ok, image_id} <- parse_image_id(params),
         :ok <- PostAdmin.delete_image(image_id, current_user(conn)) do
      redirect(conn, to: "/post/list")
    else
      {:error, :permission_denied} -> send_resp(conn, 403, "Permission Denied")
      {:error, :post_not_found} -> send_resp(conn, 404, "Not Found")
      {:error, _} -> send_resp(conn, 500, "Delete Failed")
    end
  end

  def replace_image(conn, params) do
    with {:ok, image_id} <- parse_image_id(params) do
      send_resp(conn, 501, "Replace upload flow is not ported yet (image_id=#{image_id})")
    else
      {:error, :invalid_image_id} -> send_resp(conn, 400, "Bad Request")
    end
  end

  def add_note_request(conn, params) do
    with {:ok, image_id} <- parse_image_id(params),
         :ok <- PostAdmin.add_note_request(image_id, current_user(conn)) do
      redirect(conn, to: "/post/view/#{image_id}")
    else
      {:error, :permission_denied} -> send_resp(conn, 403, "Permission Denied")
      {:error, :post_not_found} -> send_resp(conn, 404, "Not Found")
      {:error, :not_supported} -> send_resp(conn, 400, "Bad Request")
      {:error, _} -> send_resp(conn, 500, "Note Request Failed")
    end
  end

  def add_note(conn, params) do
    with {:ok, image_id} <- parse_image_id(params),
         :ok <- PostAdmin.add_note(image_id, current_user(conn), params) do
      redirect(conn, to: "/post/view/#{image_id}")
    else
      {:error, :permission_denied} -> send_resp(conn, 403, "Permission Denied")
      {:error, :post_not_found} -> send_resp(conn, 404, "Not Found")
      {:error, :not_supported} -> send_resp(conn, 400, "Bad Request")
      {:error, :invalid_note} -> send_resp(conn, 400, "Bad Request")
      {:error, _} -> send_resp(conn, 500, "Add Note Failed")
    end
  end

  def edit_note(conn, params) do
    with {:ok, image_id} <- parse_image_id(params),
         {:ok, note_id} <- parse_note_id(params),
         :ok <- PostAdmin.edit_note(image_id, note_id, current_user(conn), params) do
      redirect(conn, to: "/post/view/#{image_id}")
    else
      {:error, :permission_denied} -> send_resp(conn, 403, "Permission Denied")
      {:error, :post_not_found} -> send_resp(conn, 404, "Not Found")
      {:error, :not_supported} -> send_resp(conn, 400, "Bad Request")
      {:error, :invalid_note} -> send_resp(conn, 400, "Bad Request")
      {:error, :note_not_found} -> send_resp(conn, 404, "Not Found")
      {:error, _} -> send_resp(conn, 500, "Edit Note Failed")
    end
  end

  def delete_note(conn, params) do
    with {:ok, image_id} <- parse_image_id(params),
         {:ok, note_id} <- parse_note_id(params),
         :ok <- PostAdmin.delete_note(image_id, note_id, current_user(conn)) do
      redirect(conn, to: "/post/view/#{image_id}")
    else
      {:error, :permission_denied} -> send_resp(conn, 403, "Permission Denied")
      {:error, :post_not_found} -> send_resp(conn, 404, "Not Found")
      {:error, :not_supported} -> send_resp(conn, 400, "Bad Request")
      {:error, :note_not_found} -> send_resp(conn, 404, "Not Found")
      {:error, _} -> send_resp(conn, 500, "Delete Note Failed")
    end
  end

  def nuke_notes(conn, params) do
    with {:ok, image_id} <- parse_image_id(params),
         :ok <- PostAdmin.nuke_notes(image_id, current_user(conn)) do
      redirect(conn, to: "/post/view/#{image_id}")
    else
      {:error, :permission_denied} -> send_resp(conn, 403, "Permission Denied")
      {:error, :post_not_found} -> send_resp(conn, 404, "Not Found")
      {:error, :not_supported} -> send_resp(conn, 400, "Bad Request")
      {:error, _} -> send_resp(conn, 500, "Nuke Notes Failed")
    end
  end

  def nuke_requests(conn, params) do
    with {:ok, image_id} <- parse_image_id(params),
         :ok <- PostAdmin.nuke_requests(image_id, current_user(conn)) do
      redirect(conn, to: "/post/view/#{image_id}")
    else
      {:error, :permission_denied} -> send_resp(conn, 403, "Permission Denied")
      {:error, :post_not_found} -> send_resp(conn, 404, "Not Found")
      {:error, :not_supported} -> send_resp(conn, 400, "Bad Request")
      {:error, _} -> send_resp(conn, 500, "Nuke Requests Failed")
    end
  end

  defp current_user(conn), do: conn.assigns[:legacy_user] || Users.current_user(conn)

  defp parse_image_id(params) do
    value =
      cond do
        is_map(params) and is_binary(params["image_id"]) -> params["image_id"]
        is_map(params) and is_binary(params["id"]) -> params["id"]
        true -> nil
      end

    case Integer.parse(to_string(value || "")) do
      {id, ""} when id > 0 -> {:ok, id}
      _ -> {:error, :invalid_image_id}
    end
  end

  defp image_id_from_params(params) do
    case parse_image_id(params) do
      {:ok, id} -> id
      _ -> 0
    end
  end

  defp parse_note_id(params) do
    value =
      cond do
        is_map(params) and is_binary(params["note_id"]) -> params["note_id"]
        is_map(params) and is_binary(params["id"]) -> params["id"]
        true -> nil
      end

    case Integer.parse(to_string(value || "")) do
      {id, ""} when id > 0 -> {:ok, id}
      _ -> {:error, :invalid_note}
    end
  end
end
