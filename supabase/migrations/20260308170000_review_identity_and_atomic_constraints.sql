alter table if exists reviews
  add column if not exists entity_id_snapshot text,
  add column if not exists entity_type text,
  add column if not exists entity_display_name text,
  add column if not exists entity_category text;

update reviews
set entity_id_snapshot = coalesce(entity_id_snapshot, move_id, combo_id)
where entity_id_snapshot is null;

update reviews
set entity_type = coalesce(
  entity_type,
  case
    when combo_id is not null then 'combo'
    when move_id is not null then 'move'
    else null
  end
)
where entity_type is null;

update reviews
set entity_display_name = coalesce(
  entity_display_name,
  case
    when move_id is not null then (select name from moves where moves.id = reviews.move_id)
    when combo_id is not null then (select name from combos where combos.id = reviews.combo_id)
    else null
  end
)
where entity_display_name is null;

update reviews
set entity_category = coalesce(
  entity_category,
  case
    when move_id is not null then (select category from moves where moves.id = reviews.move_id)
    when combo_id is not null then 'combo'
    else null
  end
)
where entity_category is null;

create unique index if not exists idx_combo_moves_user_combo_move_unique
  on combo_moves (user_id, combo_id, move_id);

create unique index if not exists idx_moves_user_name_unique
  on moves (user_id, lower(trim(name)));

create unique index if not exists idx_combos_user_name_unique
  on combos (user_id, lower(trim(name)));
