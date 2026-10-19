-- Vườn Nhà: schema (enums, tables, indexes, updated_at triggers, profile auto-create).
-- Names follow docs/spec-mvp.md §4. Additions beyond the spec are listed in docs/backend.md.
-- Reserved words kept as in the spec and always quoted: "group", "order", "window".

-- ---------------------------------------------------------------- enums
create type space            as enum ('indoor','balcony','yard','rooftop');
create type watering         as enum ('manual','auto');
create type start_stage      as enum ('seed','seedling','mature');          -- declaration order = growth order
create type experience       as enum ('new','mid','pro');
create type lang             as enum ('vi','en');
create type plant_group      as enum ('rau_qua','cay_canh');
create type difficulty       as enum ('easy','medium','hard');
create type condition_tag    as enum ('LEAF_YELLOW','WILT','PESTS','SPOTS');
create type shot             as enum ('whole_plant','close_leaf','leaf_underside');
create type task_window      as enum ('morning','afternoon','all_day');
create type frequency        as enum ('once','every_n_days','daily','fixed_date');
create type assignment_mode  as enum ('once','series','rotation');
create type task_action      as enum ('done','skip','snooze');
create type member_role      as enum ('owner','member');                    -- spec enum "role"
create type project_status   as enum ('active','done','failed','archived');
create type change_kind      as enum ('add','remove','shift','change_freq');
create type plan_source      as enum ('template','ai','fallback');
create type plan_status      as enum ('draft','approved','superseded');
create type task_source      as enum ('template','ai','manual');
create type task_status      as enum ('active','archived');
create type occurrence_state as enum ('pending','done','skipped','snoozed','missed');
create type checkin_status   as enum ('pending','analyzed','retake','approved','rejected');
create type confirmed_by     as enum ('ai','user');
create type data_status      as enum ('verified','ai_unverified');
create type text_kind        as enum ('task','problem','reason','milestone','safety','tag','hint');
create type text_field       as enum ('name','steps','why','safety');
create type ai_kind          as enum ('plan','checkin');
create type xp_source        as enum ('task_done','checkin','milestone','project_done');
create type notif_type       as enum ('task_reminder','checkin_reminder','assignment','achievement','household_activity','overdue');
create type invite_channel   as enum ('link','code','email','phone');
create type invite_status    as enum ('pending','accepted','expired','revoked');
create type device_status    as enum ('pending','online','offline','disabled');

-- ---------------------------------------------------------------- generic trigger
create function public.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- ---------------------------------------------------------------- config + levels
create table public.app_config (
  key        text primary key,
  value      jsonb not null,
  note       text,
  updated_at timestamptz not null default now()
);

create table public.levels (
  level   int primary key,
  xp_min  int not null unique check (xp_min >= 0),
  name_vi text not null,
  name_en text not null
);

-- ---------------------------------------------------------------- identity and household
create table public.users (
  id             uuid primary key references auth.users(id) on delete cascade,
  display_name   text not null default '',
  avatar_path    text,
  lang           lang not null default 'vi',
  timezone       text not null default 'Asia/Ho_Chi_Minh',
  province_code  text,
  zone_code      text not null default 'VN_S' check (zone_code in ('VN_N','VN_C','VN_S')),
  experience     experience not null default 'new',
  time_budget    text not null default '10-30p' check (time_budget in ('<10p','10-30p','>30p')),
  prefer_organic boolean not null default true,
  has_children   boolean not null default false,
  has_pets       boolean not null default false,
  quiet_start    time,
  quiet_end      time,
  xp_total       int not null default 0 check (xp_total >= 0),
  level          int not null default 1,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted_at     timestamptz
);

create table public.households (
  id         uuid primary key default gen_random_uuid(),
  name       text not null default 'Nhà mình',
  owner_id   uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.household_members (
  household_id uuid not null references public.households(id) on delete cascade,
  user_id      uuid not null references public.users(id) on delete cascade,
  role         member_role not null default 'member',
  joined_at    timestamptz not null default now(),
  away_until   date,
  primary key (household_id, user_id),
  unique (user_id)                       -- one household per user
);
create index household_members_household_idx on public.household_members(household_id);

create table public.invites (
  id           uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  code         text not null,
  channel      invite_channel not null default 'code',
  target       text,
  role         member_role not null default 'member',
  created_by   uuid not null references public.users(id) on delete cascade,
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null default (now() + interval '7 days'),
  accepted_by  uuid references public.users(id) on delete set null,
  status       invite_status not null default 'pending'
);
create unique index invites_pending_code_uq on public.invites(code) where status = 'pending';
create index invites_household_idx on public.invites(household_id);

create table public.invite_attempts (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create index invite_attempts_user_idx on public.invite_attempts(user_id, created_at);

-- ---------------------------------------------------------------- plant knowledge base
create table public.plants (
  id              text primary key,                          -- slug, e.g. 'tomato_cherry' (used in template keys)
  "group"         plant_group not null,
  name_vi         text not null,
  name_en         text not null,
  scientific_name text,
  search_key      text not null default '',                  -- diacritic-free, lowercase, includes aliases
  difficulty      difficulty not null default 'easy',
  days_to_harvest int check (days_to_harvest > 0),           -- days to harvest, or plan horizon for ornamentals
  toxic_child     boolean not null default false,
  toxic_pet       boolean not null default false,
  hidden          boolean not null default false,            -- generic fallback plants, not searchable
  data_status     data_status not null default 'ai_unverified',
  sources         text[] not null default '{}',
  updated_at      timestamptz not null default now()
);
create index plants_group_idx on public.plants("group") where not hidden;

create table public.plant_stages (
  plant_id       text not null references public.plants(id) on delete cascade,
  code           text not null,
  "order"        int not null,
  name_vi        text not null,
  name_en        text not null,
  day_min        int not null check (day_min >= 1),
  day_max        int not null check (day_max >= day_min),
  milestone_code text,
  phase          start_stage not null default 'seed',        -- growth phase the stage belongs to (start_stage filter)
  primary key (plant_id, code),
  unique (plant_id, "order")
);

create table public.task_codes (
  code                  text primary key check (code ~ '^T_[A-Z0-9_]+$'),
  "group"               text not null,
  default_window        task_window not null default 'morning',
  default_frequency     frequency not null default 'every_n_days',
  default_interval_days int,
  safety_flags          text[] not null default '{}'
);

create table public.reason_codes (
  code text primary key check (code ~ '^R_[A-Z0-9_]+$')
);

create table public.milestone_codes (
  code      text primary key,
  sort_order int not null unique
);

create table public.problem_codes (
  code         text primary key check (code ~ '^P_[A-Z0-9_]+$'),
  symptoms     text[] not null default '{}',                 -- condition_tag values
  causes       text[] not null default '{}',                 -- reason_codes or free keys
  safe_actions text[] not null default '{}',                 -- task_codes (organic first)
  severity     smallint not null default 1 check (severity between 1 and 3)  -- 1 mild, 2 moderate, 3 severe
);

create table public.plant_problems (
  plant_id     text not null references public.plants(id) on delete cascade,
  problem_code text not null references public.problem_codes(code) on delete cascade,
  rank         int not null default 1,
  primary key (plant_id, problem_code)
);

-- Default per-plant plan: this is the seed template and the AI-failure fallback.
create table public.plant_default_tasks (
  plant_id    text not null references public.plants(id) on delete cascade,
  stage_code  text not null,
  task_code   text not null references public.task_codes(code),
  "window"    task_window not null default 'morning',
  every_d     int not null default 0 check (every_d between 0 and 60),   -- 0 = once, 1 = daily
  offset_d    int not null default 0 check (offset_d >= 0),              -- days after stage start for the first occurrence
  reason_code text references public.reason_codes(code),
  primary key (plant_id, stage_code, task_code),
  foreign key (plant_id, stage_code) references public.plant_stages(plant_id, code) on delete cascade
);

create table public.text_templates (
  kind       text_kind not null,
  code       text not null,
  lang       lang not null,
  field      text_field not null,
  body       text not null,
  source_ref text,
  status     data_status not null default 'ai_unverified',
  updated_at timestamptz not null default now(),
  primary key (kind, code, lang, field)
);

create table public.plan_templates (
  template_key text primary key,
  plant_id     text references public.plants(id) on delete cascade,
  zone         text not null,
  season       text not null,
  start_stage  start_stage not null,
  space        space not null,
  sun_level    int not null check (sun_level between 1 and 4),
  version      int not null default 1,
  status       text not null default 'active' check (status in ('active','retired')),
  created_by   text not null default 'ai' check (created_by in ('ai','manual')),
  hit_count    int not null default 0,
  confidence   numeric(3,2),
  body         jsonb not null,                                -- {stages:[...], tasks:[...]} same shape as AI output
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index plan_templates_plant_idx on public.plan_templates(plant_id);

-- ---------------------------------------------------------------- projects and plans
create table public.projects (
  id                uuid primary key default gen_random_uuid(),
  household_id      uuid references public.households(id) on delete set null,   -- non-null = shared with that household
  owner_id          uuid not null references public.users(id) on delete cascade,
  plant_id          text references public.plants(id),
  plant_name_custom text,                                                       -- plant not in the DB (AI creates the data)
  name              text not null,
  start_date        date not null default current_date,
  start_stage       start_stage not null default 'seed',
  pot_count         int not null default 1 check (pot_count between 1 and 100),
  space             space not null default 'balcony',
  sun_level         int not null default 3 check (sun_level between 1 and 4),
  pot_type          text,
  watering          watering not null default 'manual',
  cover_path        text,
  status            project_status not null default 'active',
  template_key      text,
  end_reason        text,
  end_note          text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  check (plant_id is not null or plant_name_custom is not null)
);
create index projects_owner_idx on public.projects(owner_id);
create index projects_household_idx on public.projects(household_id) where household_id is not null;

create table public.plans (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references public.projects(id) on delete cascade,
  version     int not null default 1,
  source      plan_source not null default 'template',
  confidence  numeric(3,2),
  model       text,
  status      plan_status not null default 'draft',
  approved_at timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (project_id, version)
);
create unique index plans_one_approved_uq on public.plans(project_id) where status = 'approved';

create table public.stages (
  id             uuid primary key default gen_random_uuid(),
  plan_id        uuid not null references public.plans(id) on delete cascade,
  idx            int not null,
  code           text not null,
  name           text not null,
  name_en        text,
  day_from       int not null check (day_from >= 1),
  day_to         int not null check (day_to >= day_from),
  milestone_code text,
  updated_at     timestamptz not null default now(),
  unique (plan_id, idx)
);
create index stages_plan_idx on public.stages(plan_id);

create table public.tasks (
  id              uuid primary key default gen_random_uuid(),
  project_id      uuid not null references public.projects(id) on delete cascade,
  stage_id        uuid references public.stages(id) on delete set null,
  task_code       text not null references public.task_codes(code),
  reason_code     text references public.reason_codes(code),
  "window"        task_window not null default 'morning',
  frequency       frequency not null default 'every_n_days',
  interval_days   int check (interval_days between 1 and 366),   -- every_n_days: N; fixed_date: day of month
  day_offset      int not null default 0 check (day_offset >= 0), -- first occurrence = stage day_from + day_offset
  reminder_time   time,
  assignee_id     uuid references public.users(id) on delete set null,
  assignment_mode assignment_mode not null default 'series',
  rotation_order  uuid[] not null default '{}',
  source          task_source not null default 'template',
  status          task_status not null default 'active',
  xp              int not null default 10 check (xp between 0 and 100),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index tasks_project_idx on public.tasks(project_id) where status = 'active';
create index tasks_stage_idx on public.tasks(stage_id);
create index tasks_assignee_idx on public.tasks(assignee_id) where assignee_id is not null;

create table public.task_occurrences (
  task_id     uuid not null references public.tasks(id) on delete cascade,
  due_date    date not null,
  project_id  uuid not null references public.projects(id) on delete cascade,
  "window"    task_window not null,
  state       occurrence_state not null default 'pending',
  assignee_id uuid references public.users(id) on delete set null,
  updated_at  timestamptz not null default now(),
  primary key (task_id, due_date)
);
create index task_occurrences_day_idx on public.task_occurrences(project_id, due_date);
create index task_occurrences_assignee_idx on public.task_occurrences(assignee_id, due_date);

create table public.task_logs (
  id              uuid primary key default gen_random_uuid(),
  task_id         uuid not null references public.tasks(id) on delete cascade,
  project_id      uuid not null references public.projects(id) on delete cascade,  -- filled by trigger
  occurrence_date date not null,
  user_id         uuid not null references public.users(id) on delete cascade,
  action          task_action not null,
  skip_reason     text,
  snooze_until    timestamptz,
  note            text check (char_length(note) <= 500),
  photo_path      text,
  client_id       uuid,                                  -- offline dedup
  acted_at        timestamptz not null default now(),    -- client action time, validated by trigger
  created_at      timestamptz not null default now()
);
create unique index task_logs_one_done_uq on public.task_logs(task_id, occurrence_date) where action = 'done';
create unique index task_logs_client_uq on public.task_logs(user_id, client_id) where client_id is not null;
create index task_logs_project_idx on public.task_logs(project_id, created_at desc);
create index task_logs_user_idx on public.task_logs(user_id, acted_at desc);

-- ---------------------------------------------------------------- check-in and AI
create table public.checkins (
  id                  uuid primary key default gen_random_uuid(),
  project_id          uuid not null references public.projects(id) on delete cascade,
  user_id             uuid not null references public.users(id) on delete cascade,
  shots               jsonb not null default '[]' check (jsonb_typeof(shots) = 'array' and jsonb_array_length(shots) <= 3),
  tags                condition_tag[] not null default '{}',
  note                text check (char_length(note) <= 200),
  status              checkin_status not null default 'pending',
  ai_result           jsonb,
  model               text,
  counts_toward_quota boolean not null default true,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create index checkins_project_idx on public.checkins(project_id, created_at desc);
create index checkins_user_idx on public.checkins(user_id, created_at desc);

create table public.checkin_changes (
  id          uuid primary key default gen_random_uuid(),
  checkin_id  uuid not null references public.checkins(id) on delete cascade,
  change_kind change_kind not null,
  payload     jsonb not null,
  accepted    boolean not null default false,
  created_at  timestamptz not null default now()
);
create index checkin_changes_checkin_idx on public.checkin_changes(checkin_id);

create table public.milestones_reached (
  id             uuid primary key default gen_random_uuid(),
  project_id     uuid not null references public.projects(id) on delete cascade,
  milestone_code text not null,
  reached_on     date not null default current_date,
  confirmed_by   confirmed_by not null default 'user',
  checkin_id     uuid references public.checkins(id) on delete set null,
  created_at     timestamptz not null default now(),
  unique (project_id, milestone_code)
);

create table public.project_lessons (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references public.users(id) on delete cascade,
  plant_id          text references public.plants(id),
  zone              text,
  season            text,
  text              text not null check (char_length(text) <= 300),
  source_project_id uuid references public.projects(id) on delete set null,
  created_at        timestamptz not null default now()
);
create index project_lessons_user_plant_idx on public.project_lessons(user_id, plant_id, created_at desc);

create table public.ai_usage (
  user_id    uuid not null references public.users(id) on delete cascade,
  day        date not null,
  kind       ai_kind not null,
  count      int not null default 0,
  model      text,
  tokens_in  bigint not null default 0,
  tokens_out bigint not null default 0,
  cache_read bigint not null default 0,
  cost_usd   numeric(10,5) not null default 0,
  primary key (user_id, day, kind)
);

create table public.ai_feedback (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.users(id) on delete cascade,
  ref_type   text not null check (ref_type in ('plan','checkin','task','checkin_change')),
  ref_id     uuid not null,
  helpful    boolean not null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------- gamification
create table public.xp_events (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.users(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null,
  source     xp_source not null,
  ref_id     uuid not null,
  amount     int not null check (amount > 0),
  day        date not null,
  created_at timestamptz not null default now(),
  unique (user_id, source, ref_id)
);
create index xp_events_user_day_idx on public.xp_events(user_id, day);

create table public.badges_catalog (
  code     text primary key,
  name_vi  text not null,
  name_en  text not null,
  criteria jsonb not null,
  sort_order int not null default 0
);

create table public.user_badges (
  user_id    uuid not null references public.users(id) on delete cascade,
  badge_code text not null references public.badges_catalog(code),
  earned_at  timestamptz not null default now(),
  primary key (user_id, badge_code)
);

-- ---------------------------------------------------------------- other
create table public.notification_prefs (
  user_id     uuid not null references public.users(id) on delete cascade,
  type        notif_type not null,
  enabled     boolean not null default true,
  bundle_daily boolean not null default false,
  quiet_start time,
  quiet_end   time,
  updated_at  timestamptz not null default now(),
  primary key (user_id, type)
);

create table public.push_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.users(id) on delete cascade,
  token      text not null,
  platform   text not null check (platform in ('android','ios','web')),
  updated_at timestamptz not null default now(),
  unique (token)
);

create table public.consents (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.users(id) on delete cascade,
  kind        text not null check (kind in ('terms','privacy','nd13','photo_ai_improvement')),
  version     text not null,
  granted     boolean not null default true,
  accepted_at timestamptz not null default now()
);
create index consents_user_idx on public.consents(user_id);

create table public.household_activity (
  id           uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  actor_id     uuid references public.users(id) on delete set null,
  kind         text not null,       -- task_done | checkin | milestone | member_joined | member_left | project_shared
  project_id   uuid references public.projects(id) on delete cascade,
  payload      jsonb not null default '{}',
  created_at   timestamptz not null default now()
);
create index household_activity_idx on public.household_activity(household_id, created_at desc);

-- IoT placeholder (Phase 3)
create table public.devices (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.users(id) on delete cascade,
  project_id  uuid references public.projects(id) on delete set null,
  kind        text not null,
  external_id text not null,
  status      device_status not null default 'pending',
  meta        jsonb not null default '{}',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (kind, external_id)
);

create table public.sensor_readings (
  id          bigint generated always as identity primary key,
  device_id   uuid not null references public.devices(id) on delete cascade,
  recorded_at timestamptz not null default now(),
  metric      text not null,        -- soil_moisture | temperature | humidity | light ...
  value       double precision not null,
  unit        text
);
create index sensor_readings_idx on public.sensor_readings(device_id, recorded_at desc);

-- ---------------------------------------------------------------- updated_at triggers
do $$
declare t text;
begin
  foreach t in array array['app_config','users','households','plan_templates','projects','plans','stages','tasks',
                           'task_occurrences','checkins','text_templates','plants','notification_prefs','push_tokens','devices']
  loop
    execute format('create trigger %I before update on public.%I for each row execute function public.set_updated_at()',
                   t || '_set_updated_at', t);
  end loop;
end $$;

-- ---------------------------------------------------------------- profile row on signup
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.users (id, display_name, lang)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'full_name',''),
             nullif(new.raw_user_meta_data->>'name',''),
             nullif(split_part(coalesce(new.email,''),'@',1),''),
             'Người trồng cây'),
    case when new.raw_user_meta_data->>'lang' = 'en' then 'en'::lang else 'vi'::lang end)
  on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
