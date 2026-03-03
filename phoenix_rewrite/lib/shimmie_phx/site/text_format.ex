defmodule ShimmiePhoenix.Site.TextFormat do
  @moduledoc """
  Minimal legacy-compatible text formatting helpers.

  Currently ports BBCode `[thumb]123[/thumb]` embeds from the local Shimmie2
  install while escaping all other user input.
  """

  alias Phoenix.HTML

  @thumb_regex ~r/\[thumb\](\d+)\[\/thumb\]/i
  @img_regex ~r/\[img\](https?:\/\/[^\s\[\]<>\"']+)\[\/img\]/i

  def format_comment_html(nil), do: ""

  def format_comment_html(text) when is_binary(text) do
    {parts, last_index} =
      Regex.scan(@thumb_regex, text, return: :index)
      |> Enum.reduce({[], 0}, fn
        [{match_start, match_len}, {id_start, id_len}], {acc, last} ->
          before = slice_binary(text, last, match_start - last)
          post_id = slice_binary(text, id_start, id_len)

          {
            [
              acc,
              escape_html(before),
              thumb_html(post_id)
            ],
            match_start + match_len
          }

        _, state ->
          state
      end)

    tail = slice_binary(text, last_index, byte_size(text) - last_index)

    [parts, escape_html(tail)]
    |> IO.iodata_to_binary()
    |> nl2br()
    |> render_img_tags()
  end

  def format_comment_html(text), do: format_comment_html(to_string(text || ""))

  defp thumb_html(post_id) do
    "<a class=\"bb-thumb\" style=\"max-width: 30%;\" href=\"/post/view/#{post_id}\">" <>
      "<img alt=\"Post ##{post_id}\" src=\"/thumb/#{post_id}/thumb\"></a>"
  end

  defp escape_html(value) do
    value
    |> HTML.html_escape()
    |> HTML.safe_to_string()
  end

  defp nl2br(value), do: String.replace(value, "\n", "<br />\n")

  defp render_img_tags(value) do
    Regex.replace(@img_regex, value, fn _, url ->
      safe_url =
        url
        |> HTML.html_escape()
        |> HTML.safe_to_string()

      "<img alt=\"user image\" style=\"max-width:300px;\" src=\"#{safe_url}\">"
    end)
  end

  defp slice_binary(_text, _start, len) when len <= 0, do: ""
  defp slice_binary(text, start, len), do: :binary.part(text, start, len)
end
