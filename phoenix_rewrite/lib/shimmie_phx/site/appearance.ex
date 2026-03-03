defmodule ShimmiePhoenix.Site.Appearance do
  @moduledoc """
  Helpers for generating a legacy Shimmie-compatible page head and theme assets.
  """

  alias ShimmiePhoenix.Site
  alias ShimmiePhoenix.Site.Store

  def site_title, do: Store.get_config("title", "Shimmie")
  def theme_name, do: Store.get_config("theme", "danbooru2")

  def css_path do
    css_paths() |> List.first()
  end

  def css_paths do
    theme = theme_name()
    primary = cache_path("style", ".css", theme)
    theme_css = theme_asset_path(theme, "style.css")

    fallback =
      if is_nil(primary) and is_nil(theme_css) do
        cache_path("style", ".css", "danbooru2")
      else
        nil
      end

    fallback_theme_css =
      if is_nil(primary) and is_nil(theme_css) and is_nil(fallback) do
        theme_asset_path("danbooru2", "style.css")
      else
        nil
      end

    [primary, theme_css, fallback, fallback_theme_css]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  def script_path do
    theme = theme_name()

    cache_path("script", ".js", theme) ||
      cache_path("script", ".js", "danbooru2")
  end

  def custom_html_headers do
    Store.get_config("custom_html_headers", "")
  end

  def contact_href do
    case Store.get_config("contact_link", "") do
      nil ->
        nil

      "" ->
        nil

      link when is_binary(link) ->
        cond do
          String.contains?(link, "://") -> link
          String.starts_with?(link, "mailto:") -> link
          String.contains?(link, "@") -> "mailto:#{link}"
          true -> link
        end
    end
  end

  def counter_mode do
    Store.get_config("home_counter", "default")
  end

  def counter_digits(post_count) when is_integer(post_count) and post_count >= 0 do
    post_count
    |> Integer.to_string()
    |> String.graphemes()
  end

  def theme_logo_path do
    case theme_name() do
      "db2_halloween" ->
        if theme_asset_exists?("db2_halloween", "logo_halloween.png") do
          "/themes/db2_halloween/logo_halloween.png"
        else
          fallback_theme_logo("db2_halloween")
        end

      theme ->
        fallback_theme_logo(theme)
    end
  end

  defp fallback_theme_logo(theme) do
    if theme_asset_exists?(theme, "logo.png") do
      "/themes/#{theme}/logo.png"
    else
      "/themes/danbooru2/logo.png"
    end
  end

  def theme_logo_dimensions do
    case theme_logo_source_path() do
      nil -> nil
      path -> image_dimensions(path)
    end
  end

  def home_title(title), do: title

  def home_title_style do
    case theme_name() do
      "db2_halloween" -> "text-decoration: none; color: #e59649;"
      _ -> "text-decoration: none;"
    end
  end

  def header_branding(default_title) do
    case theme_name() do
      "db2_halloween" ->
        badge_src =
          if theme_asset_exists?("db2_halloween", "static/favicon_64.png") do
            "/themes/db2_halloween/static/favicon_64.png"
          else
            nil
          end

        %{
          title: default_title,
          link_style: "color:#e59649;",
          badge_src: badge_src,
          badge_style: "max-width:35px;",
          badge_id: "seasonal-header-image",
          badge_class: "seasonal-header-image"
        }

      _ ->
        %{
          title: default_title,
          # Use a token-based first-paint color so title doesn't flash before theme CSS loads.
          # Falls back to classic Shimmie link blue when vars are not available yet.
          link_style: "color:var(--link-default, rgb(0, 111, 250));",
          badge_src: nil,
          badge_style: nil,
          badge_id: nil,
          badge_class: nil
        }
    end
  end

  defp cache_path(kind, extension, theme) do
    base_dir = Path.join([Site.legacy_root(), "data", "cache", kind])
    prefix = "#{theme}."

    if File.dir?(base_dir) do
      base_dir
      |> File.ls!()
      |> Enum.filter(&String.starts_with?(&1, prefix))
      |> Enum.filter(&String.ends_with?(&1, extension))
      |> Enum.map(fn file ->
        full = Path.join(base_dir, file)
        %{file: file, mtime: mtime(full)}
      end)
      |> Enum.sort_by(& &1.mtime, :desc)
      |> List.first()
      |> case do
        nil -> nil
        %{file: file} -> "/data/cache/#{kind}/#{file}"
      end
    else
      nil
    end
  end

  defp theme_asset_path(theme, filename) do
    full = Path.join([Site.legacy_root(), "themes", theme, filename])
    if File.regular?(full), do: "/themes/#{theme}/#{filename}", else: nil
  end

  defp theme_asset_exists?(theme, filename) do
    Path.join([Site.legacy_root(), "themes", theme, filename]) |> File.regular?()
  end

  defp theme_logo_source_path do
    path =
      case theme_name() do
        "db2_halloween" ->
          halloween =
            Path.join([Site.legacy_root(), "themes", "db2_halloween", "logo_halloween.png"])

          fallback = Path.join([Site.legacy_root(), "themes", "db2_halloween", "logo.png"])
          if File.regular?(halloween), do: halloween, else: fallback

        theme ->
          Path.join([Site.legacy_root(), "themes", theme, "logo.png"])
      end

    cond do
      File.regular?(path) ->
        path

      true ->
        fallback = Path.join([Site.legacy_root(), "themes", "danbooru2", "logo.png"])
        if File.regular?(fallback), do: fallback, else: nil
    end
  end

  defp image_dimensions(path) do
    with {:ok, bin} <- File.read(path) do
      case bin do
        <<137, 80, 78, 71, 13, 10, 26, 10, _chunk_len::32, "IHDR", width::32, height::32,
          _rest::binary>> ->
          {width, height}

        <<"GIF", _ver::binary-size(3), width::little-16, height::little-16, _rest::binary>> ->
          {width, height}

        _ ->
          nil
      end
    else
      _ -> nil
    end
  end

  defp mtime(path) do
    case File.stat(path) do
      {:ok, stat} -> stat.mtime
      _ -> {{1970, 1, 1}, {0, 0, 0}}
    end
  end
end
