# Legacy Parity Snapshot

Generated at: 2026-02-27T21:19:24.452665Z
Repo root: `shimmie2-elixir`
Legacy root: `shimmie2-elixir`
Enabled extensions file: `extensions_enabled.txt`

## Coverage Targets
- Extensions discovered in codebase: 139
- Extensions in active scope: 29
- Routes discovered from `page_matches`: 67
- Extension-owned tables discovered from `create_table`: 11

## Scope Rules
- This report is filtered to active extensions listed in `extensions_enabled.txt`.
- If the enabled list is missing or empty, all extension directories are included.

## Missing Enabled Extensions
- handle_archive
- handle_flash

## Extensions
- approval
- auto_tagger
- autocomplete
- ban_words
- biography
- blotter
- browser_search
- cron_uploader
- custom_html_headers
- danbooru_api
- favorites
- featured
- google_analytics
- handle_video
- home
- ipban
- notes
- pm
- random_image
- random_list
- rating
- regen_thumb
- relationships
- site_description
- sitemap
- source_history
- tag_history
- wiki
- word_filter

## Routes
- `admin/bulk_rate`
- `api/danbooru/add_post`
- `api/danbooru/find_posts`
- `api/danbooru/find_tags`
- `api/danbooru/post/create.xml`
- `api/danbooru/post/index.xml`
- `api/danbooru/post/show/{id}`
- `api/internal/autocomplete`
- `approve_image/{image_id}`
- `auto_tag/add`
- `auto_tag/export/auto_tag.csv`
- `auto_tag/import`
- `auto_tag/list`
- `auto_tag/remove`
- `blotter/add`
- `blotter/editor`
- `blotter/list`
- `blotter/remove`
- `browser_search.xml`
- `browser_search/{tag_search}`
- `cron_upload`
- `cron_upload/run`
- `disapprove_image/{image_id}`
- `favourite/add/{image_id}`
- `favourite/remove/{image_id}`
- `featured_image/download`
- `featured_image/set/{image_id}`
- `featured_image/view`
- `home`
- `ip_ban/bulk`
- `ip_ban/create`
- `ip_ban/delete`
- `ip_ban/list`
- `note/add_request`
- `note/create_note`
- `note/delete_note`
- `note/history/{note_id}`
- `note/list`
- `note/nuke_notes`
- `note/nuke_requests`
- `note/requests`
- `note/revert/{noteID}/{reviewID}`
- `note/update_note`
- `note/updated`
- `note_history/{image_id}`
- `pm/delete`
- `pm/read/{pm_id}`
- `pm/send`
- `random`
- `random/{search}`
- `random_image/{action}`
- `random_image/{action}/{search}`
- `regen_thumb/mass`
- `regen_thumb/one/{image_id}`
- `sitemap.xml`
- `source_history/all/{page}`
- `source_history/bulk_revert`
- `source_history/revert`
- `source_history/{image_id}`
- `tag_history/all/{page}`
- `tag_history/bulk_revert`
- `tag_history/revert`
- `tag_history/{image_id}`
- `user/{name}/biography`
- `wiki`
- `wiki/{title}`
- `wiki/{title}/{action}`

## Extension Tables
- `auto_tag`
- `bans`
- `blotter`
- `note_histories`
- `note_request`
- `notes`
- `private_message`
- `source_histories`
- `tag_histories`
- `user_favorites`
- `wiki_pages`
