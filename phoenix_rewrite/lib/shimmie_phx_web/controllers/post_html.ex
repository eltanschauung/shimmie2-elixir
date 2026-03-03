defmodule ShimmiePhoenixWeb.PostHTML do
  use ShimmiePhoenixWeb, :html

  alias ShimmiePhoenix.Site.TextFormat

  embed_templates "post_html/*"

  def format_post_date(value) do
    case NaiveDateTime.from_iso8601(to_string(value || "")) do
      {:ok, dt} -> Calendar.strftime(dt, "%B %-d, %Y; %H:%M")
      _ -> to_string(value || "")
    end
  end

  def human_filesize(value) when is_integer(value) and value >= 1024 * 1024 * 1024 do
    "#{Float.round(value / (1024 * 1024 * 1024), 1)}GB"
  end

  def human_filesize(value) when is_integer(value) and value >= 1024 * 1024 do
    "#{Float.round(value / (1024 * 1024), 1)}MB"
  end

  def human_filesize(value) when is_integer(value) and value >= 1024 do
    "#{Float.round(value / 1024, 1)}KB"
  end

  def human_filesize(value) when is_integer(value), do: "#{value}B"
  def human_filesize(_), do: "0B"

  def format_comment_html(text), do: TextFormat.format_comment_html(text)
end
