defmodule ShimmiePhoenixWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use ShimmiePhoenixWeb, :controller` and
  `use ShimmiePhoenixWeb, :live_view`.
  """
  use ShimmiePhoenixWeb, :html

  embed_templates "layouts/*"

  def format_blotter_date(value) do
    case NaiveDateTime.from_iso8601(to_string(value || "")) do
      {:ok, dt} -> Calendar.strftime(dt, "%m/%d/%y")
      _ -> to_string(value || "")
    end
  end

  def body_layout_class(assigns) when is_map(assigns) do
    show_chrome? =
      case Map.get(assigns, :legacy_chrome) do
        %{show?: true} -> true
        _ -> false
      end

    has_left_nav? = Map.get(assigns, :has_left_nav, false)

    if show_chrome? and has_left_nav?, do: "layout-grid", else: "layout-no-left"
  end
end
