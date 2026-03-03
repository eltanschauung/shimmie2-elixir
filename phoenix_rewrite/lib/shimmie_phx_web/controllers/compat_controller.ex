defmodule ShimmiePhoenixWeb.CompatController do
  use ShimmiePhoenixWeb, :controller

  alias ShimmiePhoenix.Repo

  def health(conn, _params) do
    db_probe =
      case Repo.query("SELECT 1") do
        {:ok, _} -> "ok"
        {:error, error} -> "error: #{Exception.message(error)}"
      end

    json(conn, %{
      status: "ok",
      compatibility_mode: true,
      db_probe: db_probe,
      version: Application.spec(:shimmie_phx, :vsn) |> to_string()
    })
  end
end
