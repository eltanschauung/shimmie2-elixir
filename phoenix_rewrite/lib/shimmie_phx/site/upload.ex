defmodule ShimmiePhoenix.Site.Upload do
  @moduledoc """
  Minimal upload write path for file-based uploads from `/upload`.
  """

  alias ShimmiePhoenix.Repo
  alias ShimmiePhoenix.Site
  alias ShimmiePhoenix.Site.Approval
  alias ShimmiePhoenix.Site.Store

  @image_exts ~w(jpg jpeg png gif webp avif)
  @allowed_upload_exts MapSet.new(~w(
                         jpg
                         jpeg
                         jfif
                         jfi
                         png
                         gif
                         webp
                         avif
                         zip
                         swf
                         asf
                         asx
                         wma
                         wmv
                         avi
                         flv
                         mkv
                         mp4
                         m4v
                         ogv
                         mov
                         webm
                       ))
  @upload_denied_classes MapSet.new(["ghost", "banned"])

  def can_upload?(%{id: id, class: class}) when is_integer(id) and id > 0 do
    normalized = normalize_class(class)

    cond do
      MapSet.member?(@upload_denied_classes, normalized) ->
        false

      anonymous_actor?(%{id: id, class: normalized}) ->
        anonymous_uploads_enabled?()

      true ->
        true
    end
  end

  def can_upload?(_), do: false

  def upload_denied_message(actor) do
    if anonymous_actor?(actor) and not anonymous_uploads_enabled?() do
      "Anonymous uploads are disabled by board settings"
    else
      "Your account class does not have upload permission"
    end
  end

  def create_file_upload(
        %Plug.Upload{} = upload,
        actor,
        remote_ip,
        common_tags,
        specific_tags,
        common_source,
        row_source
      ) do
    max_size =
      parse_size(
        Store.get_config("upload_size", Integer.to_string(10 * 1024 * 1024)),
        10 * 1024 * 1024
      )

    with {:ok, stat} <- File.stat(upload.path) do
      cond do
        stat.size <= 0 ->
          {:error, :empty_upload}

        stat.size > max_size ->
          {:error, :too_large}

        true ->
          case File.read(upload.path) do
            {:ok, bytes} ->
              hash = :crypto.hash(:md5, bytes) |> Base.encode16(case: :lower)

              if post_id_by_hash(hash) do
                {:error, :duplicate}
              else
                ext = choose_ext(upload)

                if allowed_upload_ext?(ext) do
                  filename = sanitize_filename(upload.filename, ext)
                  mime = choose_mime(ext)
                  width_height = media_dimensions(upload.path, ext)
                  source = first_non_blank([row_source, common_source])
                  tags = normalized_tags(common_tags, specific_tags)
                  now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
                  owner_id = actor_id(actor)
                  owner_ip = normalize_ip(remote_ip)
                  approved = upload_starts_approved?(actor)
                  approved_by_id = if approved, do: owner_id, else: nil

                  Repo.transaction(fn ->
                    image_id = next_id("images")
                    media_path = warehouse_path("images", hash)
                    thumb_path = warehouse_path("thumbs", hash)

                    :ok = File.mkdir_p(Path.dirname(media_path))
                    :ok = File.mkdir_p(Path.dirname(thumb_path))
                    :ok = File.cp(upload.path, media_path)
                    _ = ensure_thumb(media_path, thumb_path, ext)

                    {width, height} = width_height

                    insert_image!(
                      image_id,
                      owner_id,
                      owner_ip,
                      filename,
                      stat.size,
                      hash,
                      ext,
                      source,
                      width,
                      height,
                      now,
                      approved,
                      approved_by_id,
                      mime
                    )

                    Enum.each(tags, fn tag ->
                      tag_id = upsert_tag!(tag)

                      _ =
                        Repo.query!(
                          "INSERT INTO image_tags(image_id, tag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
                          [image_id, tag_id]
                        )
                    end)

                    maybe_insert_tag_history(image_id, owner_id, owner_ip, tags, now)
                    maybe_insert_source_history(image_id, owner_id, owner_ip, source, now)

                    image_id
                  end)
                  |> case do
                    {:ok, image_id} -> {:ok, image_id}
                    {:error, _} -> {:error, :db_failed}
                  end
                else
                  {:error, :unsupported_type}
                end
              end

            _ ->
              {:error, :invalid_upload}
          end
      end
    end
  end

  defp upload_starts_approved?(actor) do
    cond do
      not Approval.approval_supported?() -> true
      Approval.can_approve?(actor) -> true
      true -> false
    end
  end

  defp anonymous_uploads_enabled? do
    Store.get_config("upload_anon", "1")
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> then(&(&1 in ["1", "true", "yes", "on", "y"]))
  end

  defp anonymous_actor?(%{id: id, class: class}) when is_integer(id) do
    id == parse_int(Store.get_config("anon_id", "1"), 1) or normalize_class(class) == "anonymous"
  end

  defp anonymous_actor?(_), do: false

  defp normalize_class(class), do: class |> to_string() |> String.trim() |> String.downcase()

  defp actor_id(%{id: id}) when is_integer(id) and id > 0, do: id
  defp actor_id(_), do: parse_int(Store.get_config("anon_id", "1"), 1)

  defp post_id_by_hash(hash) do
    case Repo.query("SELECT id FROM images WHERE hash = $1 LIMIT 1", [hash]) do
      {:ok, %{rows: [[id]]}} -> parse_int(id, 0)
      _ -> nil
    end
  end

  defp choose_ext(upload) do
    from_name =
      upload.filename
      |> to_string()
      |> Path.extname()
      |> String.trim_leading(".")
      |> String.downcase()

    cond do
      from_name != "" ->
        from_name

      is_binary(upload.content_type) ->
        upload.content_type |> MIME.extensions() |> List.first() |> to_string()

      true ->
        "bin"
    end
  end

  defp choose_mime(ext), do: MIME.from_path("file.#{ext}") || "application/octet-stream"

  defp sanitize_filename(name, ext) do
    clean =
      name
      |> to_string()
      |> Path.basename()
      |> String.replace(~r/[^A-Za-z0-9._-]/, "_")
      |> String.trim()

    cond do
      clean == "" -> "upload.#{ext}"
      String.downcase(Path.extname(clean)) == ".#{ext}" -> clean
      String.contains?(clean, ".") -> Path.rootname(clean) <> ".#{ext}"
      true -> clean <> "." <> ext
    end
  end

  defp allowed_upload_ext?(ext), do: MapSet.member?(@allowed_upload_exts, String.downcase(ext))

  defp warehouse_path(kind, hash) do
    splits = Site.warehouse_splits()

    subdirs =
      if splits <= 0 do
        []
      else
        Enum.map(0..(splits - 1), fn i -> String.slice(hash, i * 2, 2) end)
      end

    Path.join([Site.legacy_root(), "data", kind] ++ subdirs ++ [hash])
  end

  defp media_dimensions(path, ext) do
    if ext in @image_exts do
      identify =
        Store.get_config("media_convert_path", "convert")
        |> to_string()
        |> String.replace("convert", "identify")

      case System.cmd(identify, ["-format", "%w %h", path], stderr_to_stdout: true) do
        {out, 0} ->
          case String.split(String.trim(out), " ", parts: 2) do
            [w, h] -> {parse_int(w, 0), parse_int(h, 0)}
            _ -> {0, 0}
          end

        _ ->
          {0, 0}
      end
    else
      {0, 0}
    end
  end

  defp ensure_thumb(media_path, thumb_path, ext) do
    if ext in @image_exts do
      convert = Store.get_config("media_convert_path", "convert") |> to_string() |> String.trim()
      w = parse_int(Store.get_config("thumb_width", "192"), 192)
      h = parse_int(Store.get_config("thumb_height", "192"), 192)
      alpha_bg = thumb_alpha_color()
      tmp = thumb_path <> ".tmp." <> Integer.to_string(System.unique_integer([:positive]))

      case System.cmd(
             convert,
             [
               media_path <> "[0]",
               "-auto-orient",
               "-thumbnail",
               "#{w}x#{h}>",
               "-background",
               alpha_bg,
               "-alpha",
               "remove",
               "-alpha",
               "off",
               "-strip",
               "-quality",
               "90",
               "JPEG:" <> tmp
             ],
             stderr_to_stdout: true
           ) do
        {_out, 0} ->
          File.rename(tmp, thumb_path)
          :ok

        _ ->
          _ = File.rm(tmp)
          File.cp(media_path, thumb_path)
          :ok
      end
    else
      :ok
    end
  end

  defp insert_image!(
         image_id,
         owner_id,
         owner_ip,
         filename,
         filesize,
         hash,
         ext,
         source,
         width,
         height,
         now,
         approved,
         approved_by_id,
         mime
       ) do
    Repo.query!(
      "INSERT INTO images(id, owner_id, owner_ip, filename, filesize, hash, ext, source, width, height, favorites, posted, locked, approved, approved_by_id, rating, parent_id, mime, length, video_codec, notes) " <>
        "VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,0,$11,FALSE,$12,$13,'?',NULL,$14,NULL,NULL,0)",
      [
        image_id,
        owner_id,
        owner_ip,
        filename,
        filesize,
        hash,
        ext,
        source,
        width,
        height,
        now,
        approved,
        approved_by_id,
        mime
      ]
    )
  end

  defp upsert_tag!(tag) do
    sql =
      "WITH existing AS (" <>
        "  SELECT id FROM tags WHERE tag = $1" <>
        "), next_id AS (" <>
        "  SELECT COALESCE(MAX(id), 0) + 1 AS id FROM tags" <>
        ") " <>
        "INSERT INTO tags(id, tag, count) " <>
        "SELECT COALESCE((SELECT id FROM existing), (SELECT id FROM next_id)), $1, 1 " <>
        "ON CONFLICT (tag) DO UPDATE SET count = COALESCE(tags.count, 0) + 1 " <>
        "RETURNING id"

    case Repo.query!(sql, [tag]).rows do
      [[id] | _] -> parse_int(id, 0)
      _ -> next_id("tags")
    end
  end

  defp maybe_insert_tag_history(image_id, user_id, user_ip, tags, now) do
    tags_joined = Enum.join(tags, " ")

    if table_exists?("tag_histories") and tags_joined != "" do
      Repo.query!(
        "INSERT INTO tag_histories(id, image_id, tags, user_id, user_ip, date_set) VALUES ($1, $2, $3, $4, $5, $6)",
        [next_id("tag_histories"), image_id, tags_joined, user_id, user_ip, now]
      )
    end
  end

  defp maybe_insert_source_history(image_id, user_id, user_ip, source, now) do
    if table_exists?("source_histories") and source != "" do
      Repo.query!(
        "INSERT INTO source_histories(id, image_id, source, user_id, user_ip, date_set) VALUES ($1, $2, $3, $4, $5, $6)",
        [next_id("source_histories"), image_id, source, user_id, user_ip, now]
      )
    end
  end

  defp table_exists?(table) do
    case Repo.query(
           "SELECT 1 FROM information_schema.tables WHERE table_schema = CURRENT_SCHEMA() AND table_name = $1 LIMIT 1",
           [table]
         ) do
      {:ok, %{rows: [[1]]}} -> true
      {:ok, %{rows: rows}} -> rows != []
      _ -> false
    end
  end

  defp next_id(table) do
    case Repo.query("SELECT COALESCE(MAX(id), 0) + 1 FROM #{table}", []) do
      {:ok, %{rows: [[id]]}} -> parse_int(id, 1)
      _ -> 1
    end
  end

  defp normalized_tags(common_tags, specific_tags) do
    [common_tags, specific_tags]
    |> Enum.map(&to_string(&1 || ""))
    |> Enum.join(" ")
    |> String.downcase()
    |> String.split(~r/[,\s]+/, trim: true)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp first_non_blank(values) do
    values
    |> Enum.map(&to_string(&1 || ""))
    |> Enum.map(&String.trim/1)
    |> Enum.find("", &(&1 != ""))
  end

  defp normalize_ip(value) do
    case value |> to_string() |> String.trim() do
      "" -> "0.0.0.0"
      ip -> ip
    end
  end

  defp parse_int(value, default) do
    case Integer.parse(to_string(value || "")) do
      {n, ""} -> n
      _ -> default
    end
  end

  defp parse_size(value, default) do
    raw = value |> to_string() |> String.trim()

    case Regex.run(~r/^([0-9]+(?:\.[0-9]+)?)\s*([kmgt]?b?)?$/i, raw) do
      [_, number, unit] ->
        multiplier =
          case String.downcase(unit || "") do
            "" -> 1
            "b" -> 1
            "k" -> 1024
            "kb" -> 1024
            "m" -> 1024 * 1024
            "mb" -> 1024 * 1024
            "g" -> 1024 * 1024 * 1024
            "gb" -> 1024 * 1024 * 1024
            "t" -> 1024 * 1024 * 1024 * 1024
            "tb" -> 1024 * 1024 * 1024 * 1024
            _ -> 1
          end

        case Float.parse(number) do
          {n, ""} ->
            parsed = trunc(n * multiplier)
            if(parsed > 0, do: parsed, else: default)

          _ ->
            default
        end

      _ ->
        default
    end
  end

  defp thumb_alpha_color do
    raw = Store.get_config("thumb_alpha_color", "#ffffff") |> to_string() |> String.trim()

    cond do
      Regex.match?(~r/^#[0-9a-fA-F]{6}$/, raw) -> raw
      Regex.match?(~r/^[0-9a-fA-F]{6}$/, raw) -> "#" <> raw
      true -> "#ffffff"
    end
  end
end
