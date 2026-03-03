defmodule ShimmiePhoenixWeb.HomeControllerTest do
  use ShimmiePhoenixWeb.ConnCase, async: false

  alias ShimmiePhoenix.SiteSchemaHelper
  alias ShimmiePhoenix.Repo

  setup do
    SiteSchemaHelper.ensure_legacy_tables!()
    SiteSchemaHelper.reset_legacy_tables!()

    Repo.query!("INSERT INTO config(name, value) VALUES ($1, $2)", ["front_page", "home"])
    Repo.query!("INSERT INTO config(name, value) VALUES ($1, $2)", ["title", "Example Booru"])

    Repo.query!("INSERT INTO config(name, value) VALUES ($1, $2)", [
      "home_text",
      "<p>Hello home</p>"
    ])

    Repo.query!(
      """
      INSERT INTO images(id, filename, filesize, hash, ext, source, width, height, posted)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      """,
      [
        1,
        "demo.png",
        1,
        "accccccccccccccccccccccccccccccc",
        "png",
        nil,
        1,
        1,
        ~N[2026-01-01 12:00:00]
      ]
    )

    :ok
  end

  test "GET / renders configured home front page", %{conn: conn} do
    conn = get(conn, "/")
    body = html_response(conn, 200)
    assert body =~ "Example Booru"
    assert body =~ "<p>Hello home</p>"
    assert body =~ "Serving 1 posts"
  end

  test "GET /home renders configured home page", %{conn: conn} do
    conn = get(conn, "/home")
    body = html_response(conn, 200)
    assert body =~ "Example Booru"
    assert body =~ "<p>Hello home</p>"
  end
end
