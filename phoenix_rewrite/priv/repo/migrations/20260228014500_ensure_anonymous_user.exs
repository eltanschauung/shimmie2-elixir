defmodule ShimmiePhoenix.Repo.Migrations.EnsureAnonymousUser do
  use Ecto.Migration

  def up do
    anon_id_from_config = read_config_int("anon_id")

    existing_anon_id =
      case repo().query(
             "SELECT id FROM users WHERE LOWER(name) = 'anonymous' OR LOWER(class) = 'anonymous' ORDER BY id ASC LIMIT 1"
           ) do
        {:ok, %{rows: [[id]]}} -> to_int(id)
        _ -> nil
      end

    target_id =
      cond do
        is_integer(anon_id_from_config) and anon_id_from_config > 0 and
            user_is_anonymous?(anon_id_from_config) ->
          anon_id_from_config

        is_integer(existing_anon_id) and existing_anon_id > 0 ->
          existing_anon_id

        is_integer(anon_id_from_config) and anon_id_from_config > 0 and
            user_exists?(anon_id_from_config) ->
          next_user_id()

        is_integer(anon_id_from_config) and anon_id_from_config > 0 ->
          anon_id_from_config

        user_exists?(1) ->
          next_user_id()

        true ->
          1
      end

    ensure_anonymous_row(target_id)
    upsert_config("anon_id", Integer.to_string(target_id))
  end

  def down do
    :ok
  end

  defp ensure_anonymous_row(id) do
    case repo().query("SELECT id, name, class FROM users WHERE id = $1 LIMIT 1", [id]) do
      {:ok, %{rows: [[_id, _name, _class]]}} ->
        _ =
          repo().query("UPDATE users SET name = 'Anonymous', class = 'anonymous' WHERE id = $1", [
            id
          ])

        :ok

      _ ->
        passhash = ""

        _ =
          repo().query(
            "INSERT INTO users(id, name, pass, class, joindate) VALUES ($1, 'Anonymous', $2, 'anonymous', NOW())",
            [id, passhash]
          )

        :ok
    end
  end

  defp user_exists?(id) do
    case repo().query("SELECT 1 FROM users WHERE id = $1 LIMIT 1", [id]) do
      {:ok, %{rows: [[1]]}} -> true
      {:ok, %{rows: rows}} -> rows != []
      _ -> false
    end
  end

  defp user_is_anonymous?(id) do
    case repo().query("SELECT name, class FROM users WHERE id = $1 LIMIT 1", [id]) do
      {:ok, %{rows: [[name, class]]}} ->
        name_v = name |> to_string() |> String.downcase()
        class_v = class |> to_string() |> String.downcase()
        name_v == "anonymous" or class_v == "anonymous"

      _ ->
        false
    end
  end

  defp read_config_int(name) do
    case repo().query("SELECT value FROM config WHERE name = $1 LIMIT 1", [name]) do
      {:ok, %{rows: [[value]]}} ->
        case Integer.parse(to_string(value || "")) do
          {n, ""} -> n
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp upsert_config(name, value) do
    _ =
      repo().query(
        "INSERT INTO config(name, value) VALUES ($1, $2) ON CONFLICT(name) DO UPDATE SET value = EXCLUDED.value",
        [name, value]
      )

    :ok
  end

  defp next_user_id do
    case repo().query("SELECT COALESCE(MAX(id), 0) + 1 FROM users") do
      {:ok, %{rows: [[id]]}} -> to_int(id)
      _ -> 1
    end
  end

  defp to_int(value) when is_integer(value), do: value

  defp to_int(value) do
    case Integer.parse(to_string(value || "")) do
      {n, ""} -> n
      _ -> 0
    end
  end
end
