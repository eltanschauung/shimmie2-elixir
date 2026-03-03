defmodule ShimmiePhoenixWeb.HomeController do
  use ShimmiePhoenixWeb, :controller

  alias ShimmiePhoenix.Site.Appearance
  alias ShimmiePhoenix.Site.Store

  def root(conn, _params) do
    case Store.get_config("front_page", "post/list") do
      "home" ->
        home(conn, %{})

      page when is_binary(page) and page != "" ->
        redirect(conn, to: "/" <> page)

      _ ->
        home(conn, %{})
    end
  end

  def home(conn, _params) do
    title = Store.get_config("title", "Shimmie")
    home_text = Store.get_config("home_text", "") |> sanitize_home_text()
    post_count = Store.count_posts()
    contact_href = Appearance.contact_href()
    counter_mode = Appearance.counter_mode()
    counter_digits = Appearance.counter_digits(post_count)
    main_links = home_links()
    logo_path = Appearance.theme_logo_path()
    logo_dimensions = Appearance.theme_logo_dimensions()
    preload_images = [logo_path] |> Enum.reject(&is_nil/1)

    conn
    |> maybe_put_logo_preload_header(logo_path)
    |> assign(:page_title, title)
    |> assign(:preload_images, preload_images)
    |> render(:home,
      title: title,
      home_title: Appearance.home_title(title),
      home_title_style: Appearance.home_title_style(),
      home_text: home_text,
      post_count: post_count,
      post_count_human: format_count(post_count),
      contact_href: contact_href,
      counter_mode: counter_mode,
      counter_digits: counter_digits,
      main_links: main_links,
      logo_path: logo_path,
      logo_dimensions: logo_dimensions
    )
  end

  defp maybe_put_logo_preload_header(conn, logo_path)
       when is_binary(logo_path) and logo_path != "" do
    link_value = "<#{logo_path}>; rel=preload; as=image; fetchpriority=high"

    existing = Plug.Conn.get_resp_header(conn, "link")

    combined =
      case existing do
        [] -> link_value
        values -> Enum.join(values ++ [link_value], ", ")
      end

    Plug.Conn.put_resp_header(conn, "link", combined)
  end

  defp maybe_put_logo_preload_header(conn, _), do: conn

  defp home_links do
    raw_links = Store.get_config("home_links", "")

    case parse_bbcode_links(raw_links) do
      [] ->
        [
          %{href: "/post/list", label: "Posts"},
          %{href: "/comment/list", label: "Comments"},
          %{href: "/upload", label: "Upload"},
          %{href: "/tags", label: "Tags"},
          %{href: "/wiki", label: "Wiki"}
        ]

      links ->
        links
    end
  end

  defp parse_bbcode_links(nil), do: []
  defp parse_bbcode_links(""), do: []

  defp parse_bbcode_links(text) do
    Regex.scan(~r/\[url=([^\]]+)\](.*?)\[\/url\]/i, text)
    |> Enum.map(fn [_, href, label] ->
      %{
        href: normalize_link(String.trim(href)),
        label: String.trim(label)
      }
    end)
    |> Enum.reject(&(&1.href == "" || &1.label == ""))
  end

  defp normalize_link("site://" <> rest), do: "/" <> String.trim_leading(rest, "/")
  defp normalize_link(link), do: link

  defp format_count(value) when is_integer(value) do
    digits = Integer.to_string(value)
    len = String.length(digits)
    lead = rem(len, 3)

    {head, tail} =
      if lead == 0 do
        {"", digits}
      else
        {String.slice(digits, 0, lead), String.slice(digits, lead, len - lead)}
      end

    groups =
      tail
      |> String.graphemes()
      |> Enum.chunk_every(3)
      |> Enum.map(&Enum.join/1)

    case {head, groups} do
      {"", []} -> "0"
      {"", parts} -> Enum.join(parts, ",")
      {h, []} -> h
      {h, parts} -> h <> "," <> Enum.join(parts, ",")
    end
  end

  defp sanitize_home_text(nil), do: ""

  defp sanitize_home_text(text) do
    text = to_string(text)

    content =
      case Regex.run(~r/<body\b[^>]*>(.*)<\/body>/is, text) do
        [_, inner] -> inner
        _ -> text
      end

    content
    |> then(&Regex.replace(~r/<!doctype[^>]*>/i, &1, ""))
    |> then(&Regex.replace(~r/<\/?(html|head|body)\b[^>]*>/i, &1, ""))
    |> then(&Regex.replace(~r/<meta\b[^>]*>/i, &1, ""))
    |> String.trim()
  end
end
