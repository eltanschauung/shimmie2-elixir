defmodule ShimmiePhoenix.Site.TextFormatTest do
  use ExUnit.Case, async: true

  alias ShimmiePhoenix.Site.TextFormat

  test "formats [thumb]post_id[/thumb] to linked thumbnail" do
    html = TextFormat.format_comment_html("before [thumb]123[/thumb] after")
    assert html =~ "class=\"bb-thumb\""
    assert html =~ "href=\"/post/view/123\""
    assert html =~ "src=\"/thumb/123/thumb\""
    assert html =~ "before "
    assert html =~ " after"
  end

  test "escapes non-bbcode html" do
    html = TextFormat.format_comment_html("<script>alert(1)</script> [thumb]7[/thumb]")
    assert html =~ "&lt;script&gt;alert(1)&lt;/script&gt;"
    refute html =~ "<script>alert(1)</script>"
  end
end
