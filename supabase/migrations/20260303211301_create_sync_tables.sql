-- Breakdex Cloud Sync — Supabase Schema
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New query)

-- 1. Moves
create table if not exists moves (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  learning_state text not null default 'NEW',
  category text not null default 'default',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table moves enable row level security;
create policy "Users can CRUD own moves" on moves
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 2. Combos
create table if not exists combos (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  updated_at timestamptz not null default now()
);

alter table combos enable row level security;
create policy "Users can CRUD own combos" on combos
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 3. Combo moves
create table if not exists combo_moves (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  sequence_index integer not null,
  combo_id text not null,
  move_id text not null,
  updated_at timestamptz not null default now()
);

alter table combo_moves enable row level security;
create policy "Users can CRUD own combo_moves" on combo_moves
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 4. Reviews
create table if not exists reviews (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  rating text not null,
  review_type text not null,
  reviewed_at timestamptz not null default now(),
  move_id text,
  updated_at timestamptz not null default now()
);

alter table reviews enable row level security;
create policy "Users can CRUD own reviews" on reviews
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 5. Battle results
create table if not exists battle_results (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  score integer not null,
  moves_reviewed integer not null,
  good_count integer not null,
  hard_count integer not null,
  again_count integer not null,
  longest_streak integer not null,
  difficulty text not null,
  played_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table battle_results enable row level security;
create policy "Users can CRUD own battle_results" on battle_results
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 6. Auto-update updated_at on every table
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger moves_updated_at before update on moves
  for each row execute function update_updated_at();
create trigger combos_updated_at before update on combos
  for each row execute function update_updated_at();
create trigger combo_moves_updated_at before update on combo_moves
  for each row execute function update_updated_at();
create trigger reviews_updated_at before update on reviews
  for each row execute function update_updated_at();
create trigger battle_results_updated_at before update on battle_results
  for each row execute function update_updated_at();

-- 7. Storage bucket for videos
insert into storage.buckets (id, name, public)
values ('videos', 'videos', false)
on conflict (id) do nothing;

-- Storage RLS: users can only access their own folder (user_id/*)
create policy "Users can upload own videos" on storage.objects
  for insert with check (
    bucket_id = 'videos' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can read own videos" on storage.objects
  for select using (
    bucket_id = 'videos' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can update own videos" on storage.objects
  for update using (
    bucket_id = 'videos' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can delete own videos" on storage.objects
  for delete using (
    bucket_id = 'videos' and
    auth.uid()::text = (storage.foldername(name))[1]
  );
