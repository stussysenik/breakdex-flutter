alter table if exists combos
  add column if not exists active_video_path text;

alter table if exists reviews
  add column if not exists combo_id text,
  add column if not exists fsrs_pre_state integer,
  add column if not exists fsrs_post_state integer;

create table if not exists fsrs_cards (
  entity_id text not null,
  entity_type text not null default 'move',
  user_id uuid references auth.users(id) on delete cascade not null,
  stability double precision not null default 0,
  difficulty double precision not null default 0,
  due timestamptz not null default now(),
  last_review timestamptz,
  reps integer not null default 0,
  lapses integer not null default 0,
  fsrs_state integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (entity_id, entity_type)
);

alter table fsrs_cards enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'fsrs_cards'
      and policyname = 'Users can CRUD own fsrs_cards'
  ) then
    create policy "Users can CRUD own fsrs_cards" on fsrs_cards
      for all using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end $$;

create trigger fsrs_cards_updated_at before update on fsrs_cards
  for each row execute function update_updated_at();

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'videos',
  'videos',
  false,
  1073741824,
  array['video/mp4', 'video/quicktime', 'video/mov']
)
on conflict (id) do update
set file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;
