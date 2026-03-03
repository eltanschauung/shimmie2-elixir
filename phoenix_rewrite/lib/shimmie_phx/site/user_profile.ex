defmodule ShimmiePhoenix.Site.UserProfile do
  @moduledoc """
  Legacy-compatible helpers for user profile extras (`About Me`, IP history).
  """

  alias ShimmiePhoenix.Repo
  alias ShimmiePhoenix.Site

  @sqlite_separator <<31>>
  @sqlite_row_separator <<30>>

  def biography(user_id) when is_integer(user_id) and user_id > 0 do
    case backend() do
      {:repo} -> biography_repo(user_id)
      {:sqlite, path} -> biography_sqlite(path, user_id)
    end
  end

  def biography(_), do: ""

  def set_biography(user_id, value) when is_integer(user_id) and user_id > 0 do
    clean = to_string(value || "")

    case backend() do
      {:repo} -> set_biography_repo(user_id, clean)
      {:sqlite, path} -> set_biography_sqlite(path, user_id, clean)
    end
  end

  def set_biography(_, _), do: {:error, :invalid_user}

  def ip_history(%{id: user_id, name: username}) when is_integer(user_id) and user_id > 0 do
    case backend() do
      {:repo} ->
        %{
          uploads: ip_pairs_repo("images", "owner_ip", "owner_id", "posted", user_id),
          comments: ip_pairs_repo("comments", "owner_ip", "owner_id", "posted", user_id),
          events: log_ip_pairs_repo(username)
        }

      {:sqlite, path} ->
        %{
          uploads: ip_pairs_sqlite(path, "images", "owner_ip", "owner_id", "posted", user_id),
          comments: ip_pairs_sqlite(path, "comments", "owner_ip", "owner_id", "posted", user_id),
          events: log_ip_pairs_sqlite(path, username)
        }
    end
  end

  def ip_history(_), do: %{uploads: [], comments: [], events: []}

  defp biography_repo(user_id) do
    with :ok <- ensure_repo_user_config_table(),
         {:ok, %{rows: rows}} <-
           Repo.query(
             "SELECT COALESCE(value, '') FROM user_config WHERE user_id = $1 AND name = 'biography' LIMIT 1",
             [user_id]
           ) do
      case rows do
        [[value] | _] -> to_string(value || "")
        _ -> ""
      end
    else
      _ -> ""
    end
  end

  defp biography_sqlite(path, user_id) do
    with :ok <- ensure_sqlite_user_config_table(path),
         [[value] | _] <-
           sqlite_rows(
             path,
             "SELECT COALESCE(value, '') FROM user_config WHERE user_id = #{user_id} " <>
               "AND name = 'biography' LIMIT 1"
           ) do
      to_string(value || "")
    else
      _ -> ""
    end
  end

  defp set_biography_repo(user_id, value) do
    with :ok <- ensure_repo_user_config_table(),
         {:ok, _} <-
           Repo.query(
             "INSERT INTO user_config(user_id, name, value) VALUES ($1, 'biography', $2) " <>
               "ON CONFLICT(user_id, name) DO UPDATE SET value = EXCLUDED.value",
             [user_id, value]
           ) do
      :ok
    else
      _ -> {:error, :db_failed}
    end
  end

  defp set_biography_sqlite(path, user_id, value) do
    with :ok <- ensure_sqlite_user_config_table(path),
         :ok <-
           sqlite_exec(
             path,
             "INSERT INTO user_config(user_id, name, value) VALUES (#{user_id}, 'biography', #{sqlite_literal(value)}) " <>
               "ON CONFLICT(user_id, name) DO UPDATE SET value = excluded.value"
           ) do
      :ok
    else
      _ -> {:error, :db_failed}
    end
  end

  defp ip_pairs_repo(table, ip_col, owner_col, date_col, user_id) do
    if repo_table_exists?(table) and repo_has_column?(table, ip_col) and
         repo_has_column?(table, owner_col) and repo_has_column?(table, date_col) do
      sql =
        "SELECT COALESCE(#{ip_col}, ''), COUNT(id) AS count " <>
          "FROM #{table} WHERE #{owner_col} = $1 AND COALESCE(#{ip_col}, '') <> '' " <>
          "GROUP BY #{ip_col} ORDER BY MAX(#{date_col}) DESC"

      case Repo.query(sql, [user_id]) do
        {:ok, %{rows: rows}} ->
          Enum.map(rows, fn [ip, count] -> %{ip: to_string(ip || ""), count: parse_int(count)} end)

        _ ->
          []
      end
    else
      []
    end
  end

  defp ip_pairs_sqlite(path, table, ip_col, owner_col, date_col, user_id) do
    if sqlite_table_exists?(path, table) and sqlite_has_column?(path, table, ip_col) and
         sqlite_has_column?(path, table, owner_col) and sqlite_has_column?(path, table, date_col) do
      sql =
        "SELECT COALESCE(#{ip_col}, ''), COUNT(id) AS count " <>
          "FROM #{table} WHERE #{owner_col} = #{user_id} AND COALESCE(#{ip_col}, '') <> '' " <>
          "GROUP BY #{ip_col} ORDER BY MAX(#{date_col}) DESC"

      sqlite_rows(path, sql)
      |> Enum.map(fn [ip, count] -> %{ip: to_string(ip || ""), count: parse_int(count)} end)
    else
      []
    end
  end

  defp log_ip_pairs_repo(username) when is_binary(username) do
    if repo_table_exists?("score_log") and repo_has_column?("score_log", "address") and
         repo_has_column?("score_log", "username") and repo_has_column?("score_log", "date_sent") do
      sql =
        "SELECT COALESCE(address, ''), COUNT(id) AS count " <>
          "FROM score_log WHERE username = $1 AND COALESCE(address, '') <> '' " <>
          "GROUP BY address ORDER BY MAX(date_sent) DESC"

      case Repo.query(sql, [username]) do
        {:ok, %{rows: rows}} ->
          Enum.map(rows, fn [ip, count] -> %{ip: to_string(ip || ""), count: parse_int(count)} end)

        _ ->
          []
      end
    else
      []
    end
  end

  defp log_ip_pairs_repo(_), do: []

  defp log_ip_pairs_sqlite(path, username) when is_binary(username) do
    if sqlite_table_exists?(path, "score_log") and
         sqlite_has_column?(path, "score_log", "address") and
         sqlite_has_column?(path, "score_log", "username") and
         sqlite_has_column?(path, "score_log", "date_sent") do
      sql =
        "SELECT COALESCE(address, ''), COUNT(id) AS count " <>
          "FROM score_log WHERE username = #{sqlite_literal(username)} AND COALESCE(address, '') <> '' " <>
          "GROUP BY address ORDER BY MAX(date_sent) DESC"

      sqlite_rows(path, sql)
      |> Enum.map(fn [ip, count] -> %{ip: to_string(ip || ""), count: parse_int(count)} end)
    else
      []
    end
  end

  defp log_ip_pairs_sqlite(_, _), do: []

  defp ensure_repo_user_config_table do
    case Repo.query(
           "CREATE TABLE IF NOT EXISTS user_config (" <>
             "user_id BIGINT NOT NULL, name TEXT NOT NULL, value TEXT, " <>
             "UNIQUE(user_id, name))"
         ) do
      {:ok, _} -> :ok
      _ -> {:error, :create_failed}
    end
  end

  defp ensure_sqlite_user_config_table(path) do
    sqlite_exec(
      path,
      "CREATE TABLE IF NOT EXISTS user_config (" <>
        "user_id INTEGER NOT NULL, name TEXT NOT NULL, value TEXT, UNIQUE(user_id, name))"
    )
  end

  defp repo_table_exists?(table_name) do
    case Repo.query(
           "SELECT 1 FROM information_schema.tables WHERE table_schema = CURRENT_SCHEMA() " <>
             "AND table_name = $1 LIMIT 1",
           [table_name]
         ) do
      {:ok, %{rows: [[1]]}} -> true
      {:ok, %{rows: rows}} -> rows != []
      _ -> false
    end
  end

  defp repo_has_column?(table_name, column_name) do
    case Repo.query(
           "SELECT 1 FROM information_schema.columns WHERE table_schema = CURRENT_SCHEMA() " <>
             "AND table_name = $1 AND column_name = $2 LIMIT 1",
           [table_name, column_name]
         ) do
      {:ok, %{rows: [[1]]}} -> true
      {:ok, %{rows: rows}} -> rows != []
      _ -> false
    end
  end

  defp sqlite_table_exists?(path, table_name) do
    case sqlite_rows(
           path,
           "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = #{sqlite_literal(table_name)} LIMIT 1"
         ) do
      [["1"] | _] -> true
      _ -> false
    end
  end

  defp sqlite_has_column?(path, table_name, column_name) do
    case sqlite_rows(path, "PRAGMA table_info(#{table_name})") do
      rows -> Enum.any?(rows, fn row -> Enum.at(row, 1) == column_name end)
    end
  end

  defp backend do
    case sqlite_db_path() do
      nil -> {:repo}
      path -> {:sqlite, path}
    end
  end

  defp sqlite_db_path do
    case Site.sqlite_db_path() do
      nil -> nil
      path -> if File.exists?(path), do: path, else: nil
    end
  end

  defp sqlite_rows(path, sql) do
    args = [
      "-noheader",
      "-separator",
      @sqlite_separator,
      "-newline",
      @sqlite_row_separator,
      path,
      sql
    ]

    case System.cmd("sqlite3", args, stderr_to_stdout: true) do
      {output, 0} ->
        output
        |> String.split(@sqlite_row_separator, trim: true)
        |> Enum.map(fn line -> String.split(line, @sqlite_separator) end)

      _ ->
        []
    end
  end

  defp sqlite_exec(path, sql) do
    case System.cmd("sqlite3", [path, sql], stderr_to_stdout: true) do
      {_output, 0} -> :ok
      _ -> {:error, :sqlite_failed}
    end
  end

  defp sqlite_literal(value), do: "'#{escape_sqlite_string(to_string(value))}'"
  defp escape_sqlite_string(value), do: String.replace(value, "'", "''")

  defp parse_int(value) do
    case Integer.parse(to_string(value || "")) do
      {n, ""} -> n
      _ -> 0
    end
  end
end
