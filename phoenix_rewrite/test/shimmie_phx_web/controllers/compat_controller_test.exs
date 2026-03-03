defmodule ShimmiePhoenixWeb.CompatControllerTest do
  use ShimmiePhoenixWeb.ConnCase, async: true

  test "GET /__compat/health returns compatibility status", %{conn: conn} do
    conn = get(conn, ~p"/__compat/health")
    assert response = json_response(conn, 200)
    assert response["status"] == "ok"
    assert response["compatibility_mode"] == true
    assert is_binary(response["db_probe"])
    assert is_binary(response["version"])
    refute Map.has_key?(response, "legacy_root")
    refute Map.has_key?(response, "legacy_assets_dir")
    refute Map.has_key?(response, "legacy_config_path")
    refute Map.has_key?(response, "sqlite_db_path")
  end
end
