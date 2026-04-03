alter table if exists moves
  add column if not exists archived_at timestamptz,
  add column if not exists archive_reason text;
