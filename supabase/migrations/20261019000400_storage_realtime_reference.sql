-- Vườn Nhà: storage buckets + policies, Realtime publication, static reference data.

-- ---------------------------------------------------------------- storage
-- checkins: path {household_or_user_id}/{project_id}/{uuid}.jpg  (client uploads ~768px JPEG q75)
-- avatars:  path {user_id}/avatar.jpg (project covers live in the checkins bucket as {user}/{project}/cover.jpg)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('checkins', 'checkins', false, 2097152, array['image/jpeg','image/png','image/webp']),
       ('avatars',    'avatars',    false, 2097152, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
  set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

create function public.checkin_path_ok(p_name text) returns boolean
language sql stable security definer set search_path = public as $$
  -- folder[1] must be the caller or the household the project is shared with; folder[2] is an accessible project
  select public.can_access_project(public.safe_uuid(split_part(p_name, '/', 2)))
     and (split_part(p_name, '/', 1) = auth.uid()::text
          or split_part(p_name, '/', 1) = (select p.household_id::text from public.projects p
                                           where p.id = public.safe_uuid(split_part(p_name, '/', 2))))
$$;
grant execute on function public.checkin_path_ok(text) to authenticated;

create policy checkins_objects_select on storage.objects for select to authenticated
  using (bucket_id = 'checkins' and public.can_access_project(public.safe_uuid(split_part(name, '/', 2))));
create policy checkins_objects_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'checkins' and public.checkin_path_ok(name) and lower(name) like '%.jpg');
create policy checkins_objects_delete on storage.objects for delete to authenticated
  using (bucket_id = 'checkins' and owner_id = (select auth.uid())::text);

create policy avatars_objects_select on storage.objects for select to authenticated
  using (bucket_id = 'avatars'
         and public.shares_household_with(public.safe_uuid(split_part(name, '/', 1))));
create policy avatars_objects_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and split_part(name, '/', 1) = (select auth.uid())::text);
create policy avatars_objects_update on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and split_part(name, '/', 1) = (select auth.uid())::text);
create policy avatars_objects_delete on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and split_part(name, '/', 1) = (select auth.uid())::text);

-- ---------------------------------------------------------------- Realtime
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end $$;

alter table public.tasks replica identity full;
alter table public.task_logs replica identity full;
alter table public.household_activity replica identity full;

alter publication supabase_realtime add table public.tasks, public.task_logs, public.household_activity;
alter publication supabase_realtime add table public.task_occurrences;

-- ---------------------------------------------------------------- reference data that must exist in every environment
insert into public.app_config(key, value, note) values
  ('ai_cap_plan',        '5',   'AI plan generations per user per local day'),
  ('ai_cap_checkin',     '10',  'AI photo check-ins per user per local day (retakes are refunded)'),
  ('xp_daily_cap',       '150', 'Max XP per user per local day from ordinary task_done events'),
  ('xp_checkin_per_day', '2',   'Max check-in XP awards per user per local day'),
  ('ai_escalate_below',  '0.6', 'Escalate Haiku -> Sonnet when confidence is below this'),
  ('band_high',          '0.75','confidence >= this: high band'),
  ('band_medium',        '0.5', 'confidence >= this: medium band, below: low')
on conflict (key) do nothing;

insert into public.levels(level, xp_min, name_vi, name_en) values
  (1,    0, 'Người mới',        'Newcomer'),
  (2,  250, 'Người ươm mầm',    'Sprout Keeper'),
  (3,  700, 'Người yêu cây',    'Plant Lover'),
  (4, 1250, 'Người chăm chỉ',   'Diligent Grower'),
  (5, 1500, 'Thợ vườn',         'Gardener'),
  (6, 3000, 'Nhà vườn',         'Master Gardener')
on conflict (level) do nothing;

insert into public.badges_catalog(code, name_vi, name_en, criteria, sort_order) values
  ('FIRST_SEED',     'Hạt giống đầu tiên',  'First Seed',        '{"type":"projects","n":1}', 1),
  ('SPROUT',         'Nảy mầm',             'Sprouted',          '{"type":"milestone","code":"SPROUT"}', 2),
  ('STREAK_7',       '7 ngày liên tục',     '7-Day Streak',      '{"type":"streak","n":7}', 3),
  ('TALL',           'Vươn cao',            'Reaching Up',       '{"type":"milestone","code":"HEIGHT_40"}', 4),
  ('PHOTOGRAPHER',   'Thợ chụp ảnh',        'Photographer',      '{"type":"checkins","n":10}', 5),
  ('BLOOM',          'Ra hoa',              'In Bloom',          '{"type":"milestone","code":"FLOWER"}', 6),
  ('FIRST_HARVEST',  'Thu hoạch đầu tiên',  'First Harvest',     '{"type":"milestone","code":"HARVEST"}', 7),
  ('STREAK_30',      '30 ngày liên tục',    '30-Day Streak',     '{"type":"streak","n":30}', 8),
  ('FIRST_TASK',     'Việc đầu tiên',       'First Chore',       '{"type":"tasks_done","n":1}', 9),
  ('TASKS_50',       '50 việc chăm cây',    '50 Chores',         '{"type":"tasks_done","n":50}', 10),
  ('TASKS_200',      '200 việc chăm cây',   '200 Chores',        '{"type":"tasks_done","n":200}', 11),
  ('FIRST_CHECKIN',  'Check-in đầu tiên',   'First Check-in',    '{"type":"checkins","n":1}', 12),
  ('TRUE_LEAVES',    'Ra lá thật',          'True Leaves',       '{"type":"milestone","code":"TRUE_LEAVES"}', 13),
  ('FRUIT_SET',      'Đậu quả',             'Fruit Set',         '{"type":"milestone","code":"FRUIT_SET"}', 14),
  ('FAMILY_GARDEN',  'Cả nhà cùng trồng',   'Family Garden',     '{"type":"household_size","n":2}', 15),
  ('LEVEL_5',        'Thợ vườn',            'Gardener',          '{"type":"level","n":5}', 16)
on conflict (code) do nothing;
