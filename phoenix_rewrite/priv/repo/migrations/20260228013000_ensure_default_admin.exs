defmodule ShimmiePhoenix.Repo.Migrations.EnsureDefaultAdmin do
  use Ecto.Migration

  def up do
    admin_count =
      case repo().query("SELECT COUNT(*) FROM users WHERE LOWER(class) = 'admin'") do
        {:ok, %{rows: [[count]]}} -> to_int(count)
        _ -> 0
      end

    if admin_count == 0 do
      bootstrap_password = System.get_env("SHIMMIE_BOOTSTRAP_ADMIN_PASSWORD") || "password"

      if bootstrap_password == "password" do
        IO.warn(
          "Using default bootstrap admin password. Set SHIMMIE_BOOTSTRAP_ADMIN_PASSWORD before first migration in production."
        )
      end

      passhash = Bcrypt.hash_pwd_salt(bootstrap_password)

      case repo().query("SELECT id FROM users WHERE LOWER(name) = 'admin' LIMIT 1") do
        {:ok, %{rows: [[id]]}} ->
          _ =
            repo().query(
              "UPDATE users SET class = 'admin', pass = $1 WHERE id = $2",
              [passhash, id]
            )

          :ok

        _ ->
          next_id =
            case repo().query("SELECT COALESCE(MAX(id), 0) + 1 FROM users") do
              {:ok, %{rows: [[id]]}} -> to_int(id)
              _ -> 1
            end

          _ =
            repo().query(
              "INSERT INTO users(id, name, pass, class, joindate) VALUES ($1, $2, $3, 'admin', NOW())",
              [next_id, "admin", passhash]
            )

          :ok
      end
    end
  end

  def down do
    :ok
  end

  defp to_int(value) when is_integer(value), do: value

  defp to_int(value) do
    case Integer.parse(to_string(value || "")) do
      {n, ""} -> n
      _ -> 0
    end
  end
end
