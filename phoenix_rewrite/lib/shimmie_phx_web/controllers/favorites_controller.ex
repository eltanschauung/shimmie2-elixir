defmodule ShimmiePhoenixWeb.FavoritesController do
  use ShimmiePhoenixWeb, :controller

  alias ShimmiePhoenix.Site.Favorites
  alias ShimmiePhoenix.Site.Users

  def add(conn, %{"image_id" => image_id} = params), do: set(conn, image_id, params, true)
  def remove(conn, %{"image_id" => image_id} = params), do: set(conn, image_id, params, false)

  defp set(conn, image_id, params, do_set) do
    with {post_id, ""} <- Integer.parse(image_id),
         user_id <- actor_user_id(conn, params),
         {:ok, _count} <- Favorites.set(post_id, user_id, do_set) do
      redirect(conn, to: "/post/view/#{post_id}")
    else
      {:error, :post_not_found} ->
        send_resp(conn, 404, "Not Found")

      {:error, :user_not_found} ->
        send_resp(conn, 403, "User Not Found")

      {:error, _} ->
        send_resp(conn, 500, "Favorite Operation Failed")

      _ ->
        send_resp(conn, 400, "Bad Request")
    end
  end

  defp actor_user_id(conn, params) do
    cond do
      is_binary(params["user_id"]) ->
        case Integer.parse(params["user_id"]) do
          {id, ""} when id > 0 -> id
          _ -> Favorites.default_user_id()
        end

      true ->
        case Users.session_user_id(conn) do
          id when is_integer(id) and id > 0 -> id
          _ -> Favorites.default_user_id()
        end
    end
  end
end
