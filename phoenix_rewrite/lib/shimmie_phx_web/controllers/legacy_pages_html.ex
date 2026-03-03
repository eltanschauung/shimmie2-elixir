defmodule ShimmiePhoenixWeb.LegacyPagesHTML do
  use ShimmiePhoenixWeb, :html

  alias ShimmiePhoenix.Site.TextFormat

  embed_templates "legacy_pages_html/*"

  def format_post_date(value) do
    case NaiveDateTime.from_iso8601(to_string(value || "")) do
      {:ok, dt} -> Calendar.strftime(dt, "%B %-d, %Y; %H:%M")
      _ -> to_string(value || "")
    end
  end

  def format_comment_html(text), do: TextFormat.format_comment_html(text)
end
