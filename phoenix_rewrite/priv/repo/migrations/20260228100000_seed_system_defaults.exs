defmodule ShimmiePhoenix.Repo.Migrations.SeedSystemDefaults do
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
      {"title", "Shimmie"},
      {"front_page", "post/list"},
      {"main_page", "post/list"},
      {"contact_link", ""},
      {"theme", "default"},
      {"nice_urls", "0"},
      {"upload_count", "3"},
      {"upload_size", "1048576"},
      {"upload_anon", "1"},
      {"transload_engine", "none"},
      {"upload_tlsource", "1"},
      {"index_images", "24"},
      {"image_tip", "$tags // $size // $filesize"},
      {"image_info", ""},
      {"upload_collision_handler", "error"},
      {"image_on_delete", "list"},
      {"image_show_meta", "0"},
      {"comment_captcha", "0"},
      {"comment_limit", "10"},
      {"comment_window", "5"},
      {"comment_count", "5"},
      {"comment_list_count", "10"},
      {"comment_samefags_public", "0"},
      {"thumb_engine", "gd"},
      {"thumb_mime", "image/jpeg"},
      {"thumb_width", "192"},
      {"thumb_height", "192"},
      {"thumb_fit", "Fit"},
      {"thumb_quality", "75"},
      {"thumb_scaling", "100"},
      {"thumb_alpha_color", "#ffffff"},
      {"ext_user_config_enable_api_keys", "0"},
      {"login_signup_enabled", "1"},
      {"login_tac", ""},
      {"user_loginshowprofile", "0"},
      {"avatar_host", "none"},
      {"avatar_gravatar_type", "default"},
      {"avatar_gravatar_rating", "g"},
      {"ipban_message", ipban_message_default()},
      {"media_convert_path", "convert"},
      {"media_ffmpeg_path", "ffmpeg"},
      {"media_ffprobe_path", "ffprobe"},
      {"media_mem_limit", "8388608"},
      {"video_playback_autoplay", "1"},
      {"video_playback_loop", "1"},
      {"video_playback_mute", "0"},
      {"video_enabled_formats", "video/x-flv,video/mp4,video/ogg,video/webm"},
      {"tags_min", "3"},
      {"tag_list_pages", "0"},
      {"tag_list_length", "15"},
      {"popular_tag_list_length", "15"},
      {"info_link", "https://en.wikipedia.org/wiki/$tag"},
      {"tag_list_omit_tags", "tagme*"},
      {"tag_list_image_type", "related"},
      {"tag_list_related_sort", "alphabetical"},
      {"tag_list_popular_sort", "tagcount"},
      {"tag_list_numbers", "0"},
      {"banned_words", banned_words_default()},
      {"word_filter", ""},
      {"home_links", ""},
      {"home_text", ""},
      {"home_counter", "default"},
      {"blotter_recent", "5"},
      {"blotter_color", "FF0000"},
      {"blotter_position", "subheading"},
      {"site_description", ""},
      {"site_keywords", ""},
      {"google_analytics_id", ""},
      {"search_suggestions_results_order", "a"},
      {"archive_tmp_dir", ""},
      {"archive_extract_command", "unzip -d \"%d\" \"%f\""},
      {"show_random_block", "0"},
      {"random_images_list_count", "12"},
      {"custom_html_headers", ""},
      {"sitename_in_title", "none"},
      {"wiki_revisions", "1"},
      {"wiki_tag_page_template", wiki_tag_page_template_default()},
      {"wiki_empty_taginfo", "none"},
      {"shortwikis_on_tags", "0"},
      {"sitemap_generatefull", "0"},
      {"comment_wordpress_key", ""},
      {"api_recaptcha_privkey", ""},
      {"api_recaptcha_pubkey", ""}
    ]
  end

  defp ipban_message_default do
    """
    <p>IP <b>$IP</b> has been banned until <b>$DATE</b> by <b>$ADMIN</b> because of <b>$REASON</b>
    <p>If you couldn't possibly be guilty of what you're banned for, the person we banned probably had a dynamic IP address and so do you.
    <p>See <a href="http://whatismyipaddress.com/dynamic-static">http://whatismyipaddress.com/dynamic-static</a> for more information.
    <p>$CONTACT
    """
    |> String.trim()
  end

  defp wiki_tag_page_template_default do
    """
    {body}

    [b]Aliases: [/b][i]{aliases}[/i]
    [b]Auto tags: [/b][i]{autotags}[/i]
    """
    |> String.trim()
  end

  defp banned_words_default do
    """
    a href=
    anal
    blowjob
    /buy-.*-online/
    casino
    cialis
    doors.txt
    fuck
    hot video
    kaboodle.com
    lesbian
    nexium
    penis
    /pokerst.*/
    pornhub
    porno
    purchase
    sex
    sex tape
    spinnenwerk.de
    thx for all
    TRAMADOL
    ultram
    very nice site
    viagra
    xanax
    """
    |> String.trim()
  end
end
