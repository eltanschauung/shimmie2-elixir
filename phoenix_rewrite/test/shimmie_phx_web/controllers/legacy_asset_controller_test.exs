defmodule ShimmiePhoenixWeb.LegacyAssetControllerTest do
  use ShimmiePhoenixWeb.ConnCase, async: false

  setup do
    root =
      Path.join(System.tmp_dir!(), "shimmie_phx_assets_#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join([root, "themes", "danbooru2"]))
    File.mkdir_p!(Path.join([root, "data", "config"]))
    File.mkdir_p!(Path.join([root, "data", "cache", "themes"]))

    File.write!(Path.join([root, "themes", "danbooru2", "style.css"]), "body{color:#000}")
    File.write!(Path.join([root, "themes", "danbooru2", "page.class.php"]), "<?php echo 1;")
    File.write!(Path.join([root, "data", "config", "shimmie.conf.php"]), "<?php secret();")

    old_root = Application.get_env(:shimmie_phx, :legacy_root)
    old_assets = Application.get_env(:shimmie_phx, :legacy_assets_dir)
    old_config = Application.get_env(:shimmie_phx, :legacy_config_path)

    Application.put_env(:shimmie_phx, :legacy_root, root)
    Application.put_env(:shimmie_phx, :legacy_assets_dir, Path.join(root, "assets"))

    Application.put_env(
      :shimmie_phx,
      :legacy_config_path,
      Path.join([root, "data", "config", "shimmie.conf.php"])
    )

    on_exit(fn ->
      Application.put_env(:shimmie_phx, :legacy_root, old_root)
      Application.put_env(:shimmie_phx, :legacy_assets_dir, old_assets)
      Application.put_env(:shimmie_phx, :legacy_config_path, old_config)
      File.rm_rf(root)
    end)

    :ok
  end

  test "serves allowed static theme assets", %{conn: conn} do
    conn = get(conn, "/themes/danbooru2/style.css")
    assert response(conn, 200) == "body{color:#000}"
  end

  test "blocks executable theme files", %{conn: conn} do
    conn = get(conn, "/themes/danbooru2/page.class.php")
    assert response(conn, 404) == "Not Found"
  end

  test "blocks config files under /data", %{conn: conn} do
    conn = get(conn, "/data/config/shimmie.conf.php")
    assert response(conn, 404) == "Not Found"
  end
end
