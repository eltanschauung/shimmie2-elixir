defmodule ShimmiePhoenix.Repo.Migrations.SeedTelegramAlertDefaults do
  use Ecto.Migration

  def up do
    Enum.each(defaults(), fn {name, value} ->
      _ =
        repo().query(
          "INSERT INTO config(name, value) VALUES ($1, $2) ON CONFLICT(name) DO NOTHING",
          [name, value]
        )

      :ok
    end)
  end

  def down do
    :ok
  end

  defp defaults do
    [
      {"telegram_alerts_enabled", "0"},
      {"telegram_alerts_bot_token", ""},
      {"telegram_alerts_chat_id", ""},
      {"telegram_alerts_base_url", ""},
      {"telegram_alerts_on_upload", "1"},
      {"telegram_alerts_on_approve", "1"},
      {"telegram_alerts_on_comment", "1"}
    ]
  end
end
