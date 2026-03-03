defmodule ShimmiePhoenix.SiteSchemaHelper do
  alias ShimmiePhoenix.Repo

  def ensure_legacy_tables! do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS images (
      id BIGINT PRIMARY KEY,
      owner_id BIGINT,
      owner_ip TEXT,
      filename TEXT NOT NULL,
      filesize BIGINT NOT NULL,
      hash CHAR(32) UNIQUE NOT NULL,
      ext TEXT NOT NULL,
      source TEXT,
      width INTEGER NOT NULL,
      height INTEGER NOT NULL,
      favorites INTEGER NOT NULL DEFAULT 0,
      posted TIMESTAMP NOT NULL DEFAULT NOW(),
      locked BOOLEAN NOT NULL DEFAULT FALSE
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS users (
      id BIGINT PRIMARY KEY,
      name TEXT UNIQUE NOT NULL,
      pass TEXT,
      email TEXT,
      joindate TIMESTAMP,
      class TEXT NOT NULL DEFAULT 'user'
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS tags (
      id BIGINT PRIMARY KEY,
      tag TEXT UNIQUE NOT NULL,
      count INTEGER NOT NULL DEFAULT 0
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS image_tags (
      image_id BIGINT NOT NULL,
      tag_id BIGINT NOT NULL,
      UNIQUE(image_id, tag_id)
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS config (
      name TEXT PRIMARY KEY,
      value TEXT
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS user_favorites (
      image_id BIGINT NOT NULL,
      user_id BIGINT NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      UNIQUE(image_id, user_id)
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS comments (
      id BIGINT PRIMARY KEY,
      image_id BIGINT NOT NULL,
      owner_id BIGINT NOT NULL,
      owner_ip TEXT,
      posted TIMESTAMP NOT NULL DEFAULT NOW(),
      comment TEXT NOT NULL
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS blotter (
      id BIGINT PRIMARY KEY,
      entry_date TIMESTAMP NOT NULL DEFAULT NOW(),
      entry_text TEXT NOT NULL,
      important BOOLEAN NOT NULL DEFAULT FALSE
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS wiki_pages (
      id BIGINT PRIMARY KEY,
      owner_id BIGINT,
      owner_ip TEXT,
      date TIMESTAMP NOT NULL DEFAULT NOW(),
      title TEXT NOT NULL,
      revision INTEGER NOT NULL DEFAULT 1,
      locked BOOLEAN NOT NULL DEFAULT FALSE,
      body TEXT NOT NULL
    )
    """)
  end

  def reset_legacy_tables! do
    Repo.query!("DELETE FROM wiki_pages")
    Repo.query!("DELETE FROM blotter")
    Repo.query!("DELETE FROM comments")
    Repo.query!("DELETE FROM user_favorites")
    Repo.query!("DELETE FROM image_tags")
    Repo.query!("DELETE FROM tags")
    Repo.query!("DELETE FROM images")
    Repo.query!("DELETE FROM users")
    Repo.query!("DELETE FROM config")
  end
end
