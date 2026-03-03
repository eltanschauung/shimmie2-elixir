defmodule ShimmiePhoenix.Repo.Migrations.BootstrapSiteSchema do
  use Ecto.Migration

  def up do
    Enum.each(statements(), &execute/1)
  end

  def down do
    :ok
  end

  defp statements do
    [
      """
      CREATE TABLE IF NOT EXISTS users (
        id BIGINT PRIMARY KEY,
        name TEXT UNIQUE NOT NULL,
        pass TEXT,
        email TEXT,
        joindate TIMESTAMP WITHOUT TIME ZONE,
        class TEXT NOT NULL DEFAULT 'user'
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS images (
        id BIGINT PRIMARY KEY,
        owner_id BIGINT,
        owner_ip TEXT,
        filename TEXT NOT NULL,
        filesize BIGINT NOT NULL DEFAULT 0,
        hash CHAR(32) UNIQUE NOT NULL,
        ext TEXT NOT NULL,
        source TEXT,
        width INTEGER NOT NULL DEFAULT 0,
        height INTEGER NOT NULL DEFAULT 0,
        favorites INTEGER NOT NULL DEFAULT 0,
        posted TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        locked BOOLEAN NOT NULL DEFAULT FALSE,
        approved BOOLEAN,
        approved_by_id BIGINT,
        rating TEXT,
        parent_id BIGINT,
        mime TEXT,
        length INTEGER,
        video_codec TEXT,
        notes INTEGER NOT NULL DEFAULT 0
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS tags (
        id BIGINT PRIMARY KEY,
        tag TEXT UNIQUE NOT NULL,
        count INTEGER NOT NULL DEFAULT 0
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS image_tags (
        image_id BIGINT NOT NULL,
        tag_id BIGINT NOT NULL,
        UNIQUE (image_id, tag_id)
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS config (
        name TEXT PRIMARY KEY,
        value TEXT
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS user_favorites (
        image_id BIGINT NOT NULL,
        user_id BIGINT NOT NULL,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        UNIQUE (image_id, user_id)
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS comments (
        id BIGINT PRIMARY KEY,
        image_id BIGINT NOT NULL,
        owner_id BIGINT NOT NULL,
        owner_ip TEXT,
        posted TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        comment TEXT NOT NULL
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS blotter (
        id BIGINT PRIMARY KEY,
        entry_date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        entry_text TEXT NOT NULL,
        important BOOLEAN NOT NULL DEFAULT FALSE
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS wiki_pages (
        id BIGINT PRIMARY KEY,
        owner_id BIGINT,
        owner_ip TEXT,
        date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        title TEXT NOT NULL,
        revision INTEGER NOT NULL DEFAULT 1,
        locked BOOLEAN NOT NULL DEFAULT FALSE,
        body TEXT NOT NULL
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS source_histories (
        id BIGINT PRIMARY KEY,
        image_id BIGINT NOT NULL,
        source TEXT,
        user_id BIGINT,
        user_ip TEXT,
        date_set TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS tag_histories (
        id BIGINT PRIMARY KEY,
        image_id BIGINT NOT NULL,
        tags TEXT,
        user_id BIGINT,
        user_ip TEXT,
        date_set TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS bans (
        id BIGINT PRIMARY KEY,
        ip TEXT NOT NULL,
        mode TEXT NOT NULL DEFAULT 'ban',
        reason TEXT,
        added TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        expires TIMESTAMP WITHOUT TIME ZONE,
        banner_id BIGINT
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS note_request (
        id BIGSERIAL PRIMARY KEY,
        image_id BIGINT NOT NULL,
        user_id BIGINT NOT NULL,
        date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS notes (
        id BIGSERIAL PRIMARY KEY,
        image_id BIGINT NOT NULL,
        owner_id BIGINT,
        x INTEGER,
        y INTEGER,
        width INTEGER,
        height INTEGER,
        body TEXT,
        posted TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS note_histories (
        id BIGSERIAL PRIMARY KEY,
        image_id BIGINT NOT NULL,
        note_id BIGINT,
        user_id BIGINT,
        user_ip TEXT,
        date_set TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        action TEXT,
        body TEXT
      )
      """,
      """
      CREATE INDEX IF NOT EXISTS users_name_lower_idx ON users (LOWER(name))
      """,
      """
      CREATE INDEX IF NOT EXISTS users_class_idx ON users (class)
      """,
      """
      CREATE INDEX IF NOT EXISTS images_posted_idx ON images (posted DESC, id DESC)
      """,
      """
      CREATE INDEX IF NOT EXISTS images_owner_id_idx ON images (owner_id)
      """,
      """
      CREATE INDEX IF NOT EXISTS images_approved_idx ON images (approved)
      """,
      """
      CREATE INDEX IF NOT EXISTS images_hash_idx ON images (hash)
      """,
      """
      CREATE INDEX IF NOT EXISTS tags_count_tag_idx ON tags (count DESC, tag ASC)
      """,
      """
      CREATE INDEX IF NOT EXISTS image_tags_tag_id_idx ON image_tags (tag_id)
      """,
      """
      CREATE INDEX IF NOT EXISTS image_tags_image_id_idx ON image_tags (image_id)
      """,
      """
      CREATE INDEX IF NOT EXISTS comments_image_id_id_idx ON comments (image_id, id)
      """,
      """
      CREATE INDEX IF NOT EXISTS comments_owner_id_idx ON comments (owner_id)
      """,
      """
      CREATE INDEX IF NOT EXISTS comments_posted_idx ON comments (posted DESC)
      """,
      """
      CREATE INDEX IF NOT EXISTS user_favorites_user_id_idx ON user_favorites (user_id, image_id)
      """,
      """
      CREATE INDEX IF NOT EXISTS user_favorites_image_id_idx ON user_favorites (image_id)
      """,
      """
      CREATE INDEX IF NOT EXISTS wiki_pages_title_lower_idx ON wiki_pages (LOWER(title), revision DESC)
      """,
      """
      CREATE INDEX IF NOT EXISTS source_histories_image_id_id_idx ON source_histories (image_id, id DESC)
      """,
      """
      CREATE INDEX IF NOT EXISTS tag_histories_image_id_id_idx ON tag_histories (image_id, id DESC)
      """,
      """
      CREATE INDEX IF NOT EXISTS bans_ip_idx ON bans (ip)
      """,
      """
      CREATE INDEX IF NOT EXISTS note_request_image_id_idx ON note_request (image_id)
      """,
      """
      CREATE INDEX IF NOT EXISTS notes_image_id_idx ON notes (image_id)
      """,
      """
      CREATE INDEX IF NOT EXISTS note_histories_image_id_idx ON note_histories (image_id)
      """
    ]
  end
end
