defmodule Mix.Tasks.Shimmie.Parity.Snapshot do
  use Mix.Task

  @shortdoc "Scans legacy Shimmie2 code and writes a parity snapshot report"

  @moduledoc """
  Generates `docs/parity_snapshot.md` from legacy extension metadata:
  - extension list
  - discovered page routes (`page_matches("...")`)
  - discovered extension-created tables (`create_table("...")`)
  """

  @route_re ~r/page_matches\("([^"]+)"/
  @table_re ~r/create_table\("([^"]+)"/

  @impl true
  def run(_args) do
    app_root = File.cwd!()
    repo_root = Path.expand("..", app_root)
    legacy_root = System.get_env("SHIMMIE_LEGACY_ROOT") || repo_root
    ext_root = Path.join(legacy_root, "ext")

    enabled_extensions_file =
      System.get_env("SHIMMIE_ENABLED_EXTENSIONS_FILE") ||
        Path.join(repo_root, "extensions_enabled.txt")

    unless File.dir?(ext_root) do
      Mix.raise("Legacy extension directory not found: #{ext_root}")
    end

    all_extension_dirs =
      ext_root
      |> File.ls!()
      |> Enum.sort()
      |> Enum.filter(&File.dir?(Path.join(ext_root, &1)))

    enabled_extensions = read_enabled_extensions(enabled_extensions_file)

    extension_dirs =
      if enabled_extensions == [] do
        all_extension_dirs
      else
        all_extension_dirs
        |> Enum.filter(&MapSet.member?(MapSet.new(enabled_extensions), &1))
      end

    missing_enabled =
      enabled_extensions
      |> Enum.reject(&(&1 in all_extension_dirs))

    main_files =
      extension_dirs
      |> Enum.map(&Path.join([ext_root, &1, "main.php"]))
      |> Enum.filter(&File.exists?/1)

    routes =
      main_files
      |> Enum.flat_map(fn file ->
        file
        |> File.read!()
        |> then(&Regex.scan(@route_re, &1))
        |> Enum.map(fn [_, route] -> route end)
      end)
      |> Enum.uniq()
      |> Enum.sort()

    ext_tables =
      main_files
      |> Enum.flat_map(fn file ->
        file
        |> File.read!()
        |> then(&Regex.scan(@table_re, &1))
        |> Enum.map(fn [_, table] -> table end)
      end)
      |> Enum.uniq()
      |> Enum.sort()

    report = """
    # Legacy Parity Snapshot

    Generated at: #{DateTime.utc_now() |> DateTime.to_iso8601()}
    Repo root: `#{display_path(repo_root, app_root)}`
    Legacy root: `#{display_path(legacy_root, app_root)}`
    Enabled extensions file: `#{display_path(enabled_extensions_file, app_root)}`

    ## Coverage Targets
    - Extensions discovered in codebase: #{length(all_extension_dirs)}
    - Extensions in active scope: #{length(extension_dirs)}
    - Routes discovered from `page_matches`: #{length(routes)}
    - Extension-owned tables discovered from `create_table`: #{length(ext_tables)}

    ## Scope Rules
    - This report is filtered to active extensions listed in `extensions_enabled.txt`.
    - If the enabled list is missing or empty, all extension directories are included.

    ## Missing Enabled Extensions
    #{if missing_enabled == [], do: "- (none)", else: Enum.map_join(missing_enabled, "\n", &"- #{&1}")}

    ## Extensions
    #{Enum.map_join(extension_dirs, "\n", &"- #{&1}")}

    ## Routes
    #{Enum.map_join(routes, "\n", &"- `#{&1}`")}

    ## Extension Tables
    #{Enum.map_join(ext_tables, "\n", &"- `#{&1}`")}
    """

    docs_dir = Path.join(app_root, "docs")
    File.mkdir_p!(docs_dir)
    out_path = Path.join(docs_dir, "parity_snapshot.md")
    File.write!(out_path, report)

    matrix_rows =
      ["kind,key,status,notes,test_ref"] ++
        Enum.map(extension_dirs, &"extension,#{csv_escape(&1)},todo,,") ++
        Enum.map(routes, &"route,#{csv_escape(&1)},todo,,") ++
        Enum.map(ext_tables, &"table,#{csv_escape(&1)},todo,,")

    matrix_path = Path.join(docs_dir, "parity_matrix.csv")
    File.write!(matrix_path, Enum.join(matrix_rows, "\n") <> "\n")

    Mix.shell().info("Wrote parity snapshot: #{out_path}")
    Mix.shell().info("Wrote parity matrix: #{matrix_path}")
  end

  defp csv_escape(value) do
    escaped = String.replace(value, "\"", "\"\"")
    "\"#{escaped}\""
  end

  defp display_path(path, app_root) do
    expanded = Path.expand(path)
    app = Path.expand(app_root)

    if expanded == app or String.starts_with?(expanded, app <> "/") do
      Path.relative_to(expanded, app)
    else
      Path.basename(expanded)
    end
  end

  defp read_enabled_extensions(path) do
    if File.exists?(path) do
      path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == "" || String.starts_with?(&1, "#")))
      |> Enum.uniq()
      |> Enum.sort()
    else
      []
    end
  end
end
