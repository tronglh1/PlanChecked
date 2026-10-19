-- Vườn Nhà: SQL functions (access helpers, scheduling, XP + anti-cheat, AI quota, household, account).
-- Convention: client-callable RPCs are granted to `authenticated` only; internal / service-role functions are
-- revoked from everyone and executed by Edge Functions with the service role key.

-- ---------------------------------------------------------------- small utilities
create function public.cfg_int(p_key text, p_default int) returns int
language sql stable security definer set search_path = public as $$
  select coalesce((select (value #>> '{}')::int from public.app_config where key = p_key), p_default)
$$;

create function public.vn_normalize(p_text text) returns text
language sql immutable as $$
  select regexp_replace(
    translate(coalesce(p_text,''),
      'àÀáÁạẠảẢãÃâÂầẦấẤậẬẩẨẫẪăĂằẰắẮặẶẳẲẵẴèÈéÉẹẸẻẺẽẼêÊềỀếẾệỆểỂễỄìÌíÍịỊỉỈĩĨòÒóÓọỌỏỎõÕôÔồỒốỐộỘổỔỗỖơƠờỜớỚợỢởỞỡỠùÙúÚụỤủỦũŨưƯừỪứỨựỰửỬữỮỳỲýÝỵỴỷỶỹỸđĐ',
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaeeeeeeeeeeeeeeeeeeeeeeiiiiiiiiiioooooooooooooooooooooooooooooooooouuuuuuuuuuuuuuuuuuuuuuyyyyyyyyyydd'),
    '\s+', ' ', 'g')
$$;

create function public.vn_search_key(p_text text) returns text
language sql immutable as $$ select lower(public.vn_normalize(p_text)) $$;

create function public.user_local_date(p_user uuid, p_ts timestamptz default now()) returns date
language sql stable security definer set search_path = public as $$
  select (p_ts at time zone coalesce((select timezone from public.users where id = p_user), 'Asia/Ho_Chi_Minh'))::date
$$;

-- ---------------------------------------------------------------- access helpers (used by RLS)
create function public.is_household_member(p_household uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.household_members m where m.household_id = p_household and m.user_id = auth.uid())
$$;

create function public.is_household_owner(p_household uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.household_members m
                 where m.household_id = p_household and m.user_id = auth.uid() and m.role = 'owner')
$$;

create function public.my_household_id() returns uuid
language sql stable security definer set search_path = public as $$
  select household_id from public.household_members where user_id = auth.uid()
$$;

create function public.shares_household_with(p_user uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select p_user = auth.uid() or exists (
    select 1 from public.household_members a join public.household_members b on a.household_id = b.household_id
    where a.user_id = auth.uid() and b.user_id = p_user)
$$;

create function public.can_access_project(p_project uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.projects p
    where p.id = p_project
      and (p.owner_id = auth.uid()
           or (p.household_id is not null and exists (
                 select 1 from public.household_members m
                 where m.household_id = p.household_id and m.user_id = auth.uid()))))
$$;

-- Manage = edit plan/tasks/assign: project owner, or Owner role of the household the project is shared with.
create function public.can_manage_project(p_project uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.projects p
    where p.id = p_project
      and (p.owner_id = auth.uid()
           or (p.household_id is not null and exists (
                 select 1 from public.household_members m
                 where m.household_id = p.household_id and m.user_id = auth.uid() and m.role = 'owner'))))
$$;

create function public.plan_project(p_plan uuid) returns uuid
language sql stable security definer set search_path = public as $$
  select project_id from public.plans where id = p_plan
$$;

create function public.checkin_project(p_checkin uuid) returns uuid
language sql stable security definer set search_path = public as $$
  select project_id from public.checkins where id = p_checkin
$$;

create function public.safe_uuid(p_text text) returns uuid
language plpgsql immutable as $$
begin
  return p_text::uuid;
exception when others then
  return null;
end $$;

-- ---------------------------------------------------------------- plant search (unaccented, token based)
create function public.search_plants(p_query text, p_group plant_group default null, p_limit int default 20)
returns setof public.plants
language sql stable security invoker set search_path = public as $$
  with q as (select public.vn_search_key(trim(p_query)) as k)
  select p.*
  from public.plants p, q
  where not p.hidden
    and (p_group is null or p."group" = p_group)
    and (q.k = '' or not exists (select 1 from unnest(string_to_array(q.k, ' ')) t where t <> '' and position(t in p.search_key) = 0))
  order by (case when q.k = '' then 0
                 when public.vn_search_key(p.name_vi) like q.k || '%' then 0
                 when p.search_key like q.k || '%' then 1
                 else 2 end),
           p.difficulty, p.name_vi
  limit greatest(1, least(p_limit, 50))
$$;

-- ---------------------------------------------------------------- scheduling (single source of truth for "is task due")
create function public.task_due_on(p_task uuid, p_date date) returns boolean
language plpgsql stable security definer set search_path = public as $$
declare
  t public.tasks%rowtype;
  v_start date;
  v_from int := 1;
  v_to int := 100000;
  v_day int;
  v_first int;
begin
  select * into t from public.tasks where id = p_task;
  if not found or t.status <> 'active' then return false; end if;
  select start_date into v_start from public.projects where id = t.project_id;
  if t.stage_id is not null then
    select day_from, day_to into v_from, v_to from public.stages where id = t.stage_id;
  end if;
  v_day := (p_date - v_start) + 1;
  v_first := v_from + t.day_offset;
  if v_day < v_first or v_day > v_to then return false; end if;
  return case t.frequency
    when 'once'         then v_day = v_first
    when 'daily'        then true
    when 'every_n_days' then ((v_day - v_first) % greatest(coalesce(t.interval_days, 1), 1)) = 0
    when 'fixed_date'   then extract(day from p_date)::int = coalesce(t.interval_days, 1)
  end;
end $$;

create function public.materialize_occurrences(p_project uuid, p_from date default null, p_to date default null)
returns int
language plpgsql security definer set search_path = public as $$
declare
  v_from date := coalesce(p_from, current_date);
  v_to   date := least(coalesce(p_to, current_date + 14), coalesce(p_from, current_date) + 62);
  v_start date;
  t record;
  d record;
  n int := 0;
  v_assignee uuid;
begin
  if not public.can_access_project(p_project) and auth.uid() is not null then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  select start_date into v_start from public.projects where id = p_project;
  for t in select * from public.tasks where project_id = p_project and status = 'active' loop
    for d in
      select x.due, row_number() over (order by x.due) - 1 as ord
      from (select g::date as due from generate_series(v_start, v_to, interval '1 day') g) x
      where public.task_due_on(t.id, x.due)
    loop
      continue when d.due < v_from;
      v_assignee := case
        when t.assignment_mode = 'rotation' and cardinality(t.rotation_order) > 0
          then t.rotation_order[1 + (d.ord % cardinality(t.rotation_order))::int]
        else t.assignee_id end;
      insert into public.task_occurrences(task_id, due_date, project_id, "window", assignee_id)
      values (t.id, d.due, p_project, t."window", v_assignee)
      on conflict (task_id, due_date) do nothing;
      n := n + 1;
    end loop;
  end loop;
  return n;
end $$;

-- ---------------------------------------------------------------- levels, streak, badges
create function public.level_for_xp(p_xp int) returns int
language sql stable security definer set search_path = public as $$
  select coalesce(max(level), 1) from public.levels where xp_min <= p_xp
$$;

create function public.user_streak(p_user uuid) returns int
language sql stable security definer set search_path = public as $$
  with tz as (select coalesce((select timezone from public.users where id = p_user), 'Asia/Ho_Chi_Minh') as z),
  days as (
    select distinct (l.acted_at at time zone tz.z)::date as day
    from public.task_logs l, tz where l.user_id = p_user and l.action = 'done'
  ),
  ranked as (select day, (day + (row_number() over (order by day desc))::int) as grp from days),
  today as (select (now() at time zone (select z from tz))::date as d),
  first_grp as (select grp from ranked, today where day = (select max(day) from days) and day >= today.d - 1 limit 1)
  select coalesce((select count(*)::int from ranked where grp = (select grp from first_grp)), 0)
$$;

create function public.evaluate_badges(p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  b record;
  v_ok boolean;
  v_n int;
begin
  for b in select * from public.badges_catalog loop
    v_n := nullif(b.criteria->>'n','')::int;
    v_ok := case b.criteria->>'type'
      when 'projects'  then (select count(*) from public.projects where owner_id = p_user) >= v_n
      when 'tasks_done' then (select count(*) from public.task_logs where user_id = p_user and action = 'done') >= v_n
      when 'checkins'  then (select count(*) from public.checkins
                             where user_id = p_user and counts_toward_quota and status in ('analyzed','approved')) >= v_n
      when 'milestone' then exists (select 1 from public.milestones_reached m join public.projects p on p.id = m.project_id
                                    where p.owner_id = p_user and m.milestone_code = b.criteria->>'code'
                                      and m.checkin_id is not null)         -- photo-confirmed only
      when 'streak'    then public.user_streak(p_user) >= v_n
      when 'household_size' then coalesce((select count(*) from public.household_members
                                           where household_id = (select household_id from public.household_members where user_id = p_user)), 0) >= v_n
      when 'level'     then (select level from public.users where id = p_user) >= v_n
      else false end;
    if v_ok then
      insert into public.user_badges(user_id, badge_code) values (p_user, b.code) on conflict do nothing;
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------- XP (server-side only)
-- Rules (spec §6.3-6.5, gaps decided in docs/backend.md):
--   task_done  +10 only when logged on the occurrence day (user's timezone) for a task that is really due that day;
--              all task_done XP per user-day capped at app_config.xp_daily_cap (150); one award per (task, day).
--   checkin    +30 only when AI analysis succeeded (not retake); max 1 per project per day, max 2 per user per day;
--              outside the 150 cap.
--   milestone  +100 only when the milestone row is attached to an analyzed checkin of the same project (photo-confirmed).
--   project_done +200 once, only if the project has at least one photo-confirmed milestone.
create function public.award_xp(p_user uuid, p_project uuid, p_source xp_source, p_ref uuid, p_amount int,
                                p_at timestamptz default now())
returns int
language plpgsql security definer set search_path = public as $$
declare
  v_day date;
  v_amt int := p_amount;
  v_used int;
  v_total int;
begin
  if v_amt is null or v_amt <= 0 then return 0; end if;
  v_day := public.user_local_date(p_user, p_at);
  perform pg_advisory_xact_lock(hashtextextended(p_user::text || ':xp', 0));

  if exists (select 1 from public.xp_events where user_id = p_user and source = p_source and ref_id = p_ref) then
    return 0;
  end if;

  if p_source = 'task_done' then
    select coalesce(sum(amount), 0) into v_used from public.xp_events
      where user_id = p_user and day = v_day and source = 'task_done';
    v_amt := least(v_amt, public.cfg_int('xp_daily_cap', 150) - v_used);
  elsif p_source = 'checkin' then
    if (select count(*) from public.xp_events where user_id = p_user and day = v_day and source = 'checkin')
         >= public.cfg_int('xp_checkin_per_day', 2)
       or exists (select 1 from public.xp_events where user_id = p_user and day = v_day and source = 'checkin' and project_id = p_project)
    then
      return 0;
    end if;
  end if;
  if v_amt <= 0 then return 0; end if;

  insert into public.xp_events(user_id, project_id, source, ref_id, amount, day)
  values (p_user, p_project, p_source, p_ref, v_amt, v_day);
  update public.users set xp_total = xp_total + v_amt where id = p_user returning xp_total into v_total;
  update public.users set level = public.level_for_xp(v_total) where id = p_user;
  perform public.evaluate_badges(p_user);
  return v_amt;
end $$;

-- Protect server-owned columns on users from client updates.
create function public.users_protect_columns() returns trigger
language plpgsql as $$
begin
  if current_user in ('authenticated','anon') then
    new.xp_total := old.xp_total;
    new.level := old.level;
    new.deleted_at := old.deleted_at;
    new.id := old.id;
  end if;
  return new;
end $$;
create trigger users_protect_columns before update on public.users
  for each row execute function public.users_protect_columns();

-- ---------------------------------------------------------------- household activity
create function public.log_activity(p_household uuid, p_actor uuid, p_kind text, p_project uuid, p_payload jsonb)
returns void
language sql security definer set search_path = public as $$
  insert into public.household_activity(household_id, actor_id, kind, project_id, payload)
  select p_household, p_actor, p_kind, p_project, coalesce(p_payload, '{}')
  where p_household is not null
$$;

-- ---------------------------------------------------------------- task_logs triggers
create function public.task_logs_before_insert() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_project uuid;
  v_tz_today date;
begin
  select project_id into v_project from public.tasks where id = new.task_id;
  if v_project is null then raise exception 'task_not_found' using errcode = 'P0404'; end if;
  new.project_id := v_project;
  if auth.uid() is not null then new.user_id := auth.uid(); end if;

  -- validate the client timestamp: never in the future, never older than 7 days
  if new.acted_at is null or new.acted_at > now() or new.acted_at < now() - interval '7 days' then
    new.acted_at := now();
  end if;
  if new.action in ('done','skip') and new.occurrence_date > public.user_local_date(new.user_id, new.acted_at) then
    raise exception 'future_occurrence' using errcode = 'P0422';
  end if;
  if new.action = 'snooze' and new.snooze_until is null then
    new.snooze_until := now() + interval '1 day';
  end if;
  return new;
end $$;
create trigger task_logs_before_insert before insert on public.task_logs
  for each row execute function public.task_logs_before_insert();

create function public.task_logs_after_insert() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_xp int;
  v_household uuid;
  v_code text;
  v_ontime boolean;
begin
  select household_id into v_household from public.projects where id = new.project_id;
  select task_code, least(xp, 10) into v_code, v_xp from public.tasks where id = new.task_id;

  update public.task_occurrences
     set state = case new.action when 'done' then 'done'::occurrence_state
                                 when 'skip' then 'skipped'::occurrence_state
                                 else 'snoozed'::occurrence_state end
   where task_id = new.task_id and due_date = new.occurrence_date;

  if new.action = 'done' then
    v_ontime := public.user_local_date(new.user_id, new.acted_at) = new.occurrence_date
                and public.task_due_on(new.task_id, new.occurrence_date);
    if v_ontime then
      -- ref = deterministic id of (task, day) so undo/redo can never earn twice
      perform public.award_xp(new.user_id, new.project_id, 'task_done',
                              md5(new.task_id::text || ':' || new.occurrence_date::text)::uuid, v_xp, new.acted_at);
    end if;
    perform public.evaluate_badges(new.user_id);
    perform public.log_activity(v_household, new.user_id, 'task_done', new.project_id,
                                jsonb_build_object('task_id', new.task_id, 'task_code', v_code, 'date', new.occurrence_date));
  end if;
  return new;
end $$;
create trigger task_logs_after_insert after insert on public.task_logs
  for each row execute function public.task_logs_after_insert();

-- ---------------------------------------------------------------- checkins / milestones / project triggers
create function public.checkins_before_insert() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null then new.user_id := auth.uid(); end if;
  if auth.uid() is not null then   -- clients cannot pre-fill server-owned fields
    new.status := 'pending'; new.ai_result := null; new.model := null; new.counts_toward_quota := true;
  end if;
  return new;
end $$;
create trigger checkins_before_insert before insert on public.checkins
  for each row execute function public.checkins_before_insert();

create function public.checkins_after_insert() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.log_activity((select household_id from public.projects where id = new.project_id),
                              new.user_id, 'checkin', new.project_id, jsonb_build_object('checkin_id', new.id));
  return new;
end $$;
create trigger checkins_after_insert after insert on public.checkins
  for each row execute function public.checkins_after_insert();

create function public.checkins_after_update() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'analyzed' and old.status is distinct from 'analyzed' and new.counts_toward_quota then
    perform public.award_xp(new.user_id, new.project_id, 'checkin', new.id, 30, now());
    perform public.evaluate_badges(new.user_id);
  end if;
  return new;
end $$;
create trigger checkins_after_update after update of status on public.checkins
  for each row execute function public.checkins_after_update();

create function public.milestones_after_insert() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  c public.checkins%rowtype;
  v_actor uuid := auth.uid();
begin
  if new.checkin_id is not null then
    select * into c from public.checkins where id = new.checkin_id;
    if found then
      v_actor := c.user_id;
      if c.project_id = new.project_id and c.status in ('analyzed','approved') then
        perform public.award_xp(c.user_id, new.project_id, 'milestone', new.id, 100, now());
        perform public.evaluate_badges(c.user_id);
      end if;
    end if;
  end if;
  perform public.log_activity((select household_id from public.projects where id = new.project_id),
                              v_actor, 'milestone', new.project_id, jsonb_build_object('milestone_code', new.milestone_code));
  return new;
end $$;
create trigger milestones_after_insert after insert on public.milestones_reached
  for each row execute function public.milestones_after_insert();

create function public.projects_after_insert() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.evaluate_badges(new.owner_id);
  if new.household_id is not null then
    perform public.log_activity(new.household_id, new.owner_id, 'project_shared', new.id, jsonb_build_object('name', new.name));
  end if;
  return new;
end $$;
create trigger projects_after_insert after insert on public.projects
  for each row execute function public.projects_after_insert();

create function public.projects_after_update() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'done' and old.status is distinct from 'done'
     and exists (select 1 from public.milestones_reached where project_id = new.id and checkin_id is not null) then
    perform public.award_xp(new.owner_id, new.id, 'project_done', new.id, 200, now());
  end if;
  if new.household_id is not null and new.household_id is distinct from old.household_id then
    perform public.log_activity(new.household_id, new.owner_id, 'project_shared', new.id, jsonb_build_object('name', new.name));
  end if;
  return new;
end $$;
create trigger projects_after_update after update on public.projects
  for each row execute function public.projects_after_update();

-- ---------------------------------------------------------------- AI quota
create function public.consume_ai_quota(p_kind ai_kind) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_day date;
  v_cap int;
  v_used int;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  v_cap := public.cfg_int('ai_cap_' || p_kind::text, case p_kind when 'plan' then 5 else 10 end);
  v_day := public.user_local_date(v_uid);
  insert into public.ai_usage(user_id, day, kind, count) values (v_uid, v_day, p_kind, 0)
    on conflict (user_id, day, kind) do nothing;
  update public.ai_usage u set count = u.count + 1
    where u.user_id = v_uid and u.day = v_day and u.kind = p_kind and u.count < v_cap
    returning u.count into v_used;
  if v_used is null then
    raise exception 'ai_quota_exceeded' using errcode = 'P0429', detail = format('kind=%s cap=%s', p_kind, v_cap);
  end if;
  return jsonb_build_object('kind', p_kind, 'used', v_used, 'cap', v_cap, 'remaining', v_cap - v_used);
end $$;

create function public.get_ai_quota() returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_object_agg(k.kind, jsonb_build_object(
           'used', coalesce(u.count, 0),
           'cap', public.cfg_int('ai_cap_' || k.kind, case k.kind when 'plan' then 5 else 10 end)))
  from (values ('plan'), ('checkin')) k(kind)
  left join public.ai_usage u on u.user_id = auth.uid() and u.day = public.user_local_date(auth.uid()) and u.kind::text = k.kind
$$;

-- service role only: refund (retake / AI failure) and usage metering
create function public.ai_quota_refund(p_user uuid, p_kind ai_kind) returns void
language sql security definer set search_path = public as $$
  update public.ai_usage set count = greatest(count - 1, 0)
  where user_id = p_user and kind = p_kind and day = public.user_local_date(p_user)
$$;

create function public.ai_usage_record(p_user uuid, p_kind ai_kind, p_model text, p_in int, p_out int, p_cache int, p_cost numeric)
returns void
language sql security definer set search_path = public as $$
  insert into public.ai_usage(user_id, day, kind, count, model, tokens_in, tokens_out, cache_read, cost_usd)
  values (p_user, public.user_local_date(p_user), p_kind, 0, p_model, p_in, p_out, p_cache, p_cost)
  on conflict (user_id, day, kind) do update
    set model = excluded.model,
        tokens_in = ai_usage.tokens_in + excluded.tokens_in,
        tokens_out = ai_usage.tokens_out + excluded.tokens_out,
        cache_read = ai_usage.cache_read + excluded.cache_read,
        cost_usd = ai_usage.cost_usd + excluded.cost_usd
$$;

-- ---------------------------------------------------------------- household RPCs
create function public.create_household(p_name text default 'Nhà mình') returns public.households
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  h public.households;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  if exists (select 1 from public.household_members where user_id = v_uid) then
    raise exception 'already_in_household' using errcode = 'P0409';
  end if;
  insert into public.households(name, owner_id) values (coalesce(nullif(trim(p_name), ''), 'Nhà mình'), v_uid) returning * into h;
  insert into public.household_members(household_id, user_id, role) values (h.id, v_uid, 'owner');
  perform public.evaluate_badges(v_uid);
  return h;
end $$;

create function public.create_invite(p_channel invite_channel default 'code', p_target text default null,
                                     p_role member_role default 'member')
returns public.invites
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_h uuid;
  v_code text;
  i public.invites;
  v_try int := 0;
begin
  select m.household_id into v_h from public.household_members m where m.user_id = v_uid and m.role = 'owner';
  if v_h is null then raise exception 'not_household_owner' using errcode = '42501'; end if;
  if (select count(*) from public.invites where household_id = v_h and created_at > now() - interval '1 day') >= 20 then
    raise exception 'too_many_invites' using errcode = 'P0429';
  end if;
  loop
    v_code := 'VUON-' || lpad((floor(random() * 10000))::int::text, 4, '0');
    exit when not exists (select 1 from public.invites where code = v_code and status = 'pending');
    v_try := v_try + 1;
    if v_try > 50 then raise exception 'no_code_available'; end if;
  end loop;
  insert into public.invites(household_id, code, channel, target, role, created_by)
  values (v_h, v_code, p_channel, nullif(trim(p_target), ''), p_role, v_uid) returning * into i;
  return i;
end $$;

create function public.revoke_invite(p_invite uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  update public.invites i set status = 'revoked'
  where i.id = p_invite and i.status = 'pending' and public.is_household_owner(i.household_id);
end $$;

-- Returns {ok:true, household_id} or {ok:false, error}. Failures are returned (not raised) so attempts are recorded.
create function public.accept_invite(p_code text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  i public.invites;
  v_code text := upper(trim(coalesce(p_code, '')));
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  if (select count(*) from public.invite_attempts where user_id = v_uid and created_at > now() - interval '1 hour') >= 10 then
    return jsonb_build_object('ok', false, 'error', 'too_many_attempts');
  end if;
  if exists (select 1 from public.household_members where user_id = v_uid) then
    return jsonb_build_object('ok', false, 'error', 'already_in_household');
  end if;
  select * into i from public.invites where code = v_code and status = 'pending' for update;
  if not found then
    insert into public.invite_attempts(user_id) values (v_uid);
    return jsonb_build_object('ok', false, 'error', 'invite_invalid');
  end if;
  if i.expires_at < now() then
    update public.invites set status = 'expired' where id = i.id;
    return jsonb_build_object('ok', false, 'error', 'invite_expired');
  end if;
  insert into public.household_members(household_id, user_id, role) values (i.household_id, v_uid, i.role);
  update public.invites set status = 'accepted', accepted_by = v_uid where id = i.id;
  perform public.log_activity(i.household_id, v_uid, 'member_joined', null, '{}');
  perform public.evaluate_badges(v_uid);
  return jsonb_build_object('ok', true, 'household_id', i.household_id, 'role', i.role);
end $$;

-- Internal: remove user from household. Owner leaving: ownership passes to the longest-standing member;
-- last member leaving deletes the household. Projects shared with it become private (household_id -> null).
create function public._leave_household(p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  m public.household_members;
  v_next uuid;
begin
  select * into m from public.household_members where user_id = p_user;
  if not found then return; end if;
  update public.projects set household_id = null where household_id = m.household_id and owner_id = p_user;
  if m.role = 'owner' then
    select user_id into v_next from public.household_members
      where household_id = m.household_id and user_id <> p_user order by joined_at limit 1;
    if v_next is null then
      delete from public.households where id = m.household_id;   -- cascades members, invites, activity
      return;
    end if;
    update public.household_members set role = 'owner' where household_id = m.household_id and user_id = v_next;
    update public.households set owner_id = v_next where id = m.household_id;
  end if;
  delete from public.household_members where user_id = p_user;
  perform public.log_activity(m.household_id, p_user, 'member_left', null, '{}');
end $$;

create function public.leave_household() returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  perform public._leave_household(auth.uid());
end $$;

create function public.remove_member(p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
declare v_h uuid;
begin
  select household_id into v_h from public.household_members where user_id = auth.uid() and role = 'owner';
  if v_h is null then raise exception 'not_household_owner' using errcode = '42501'; end if;
  if p_user = auth.uid() then raise exception 'use_leave_household' using errcode = 'P0400'; end if;
  if not exists (select 1 from public.household_members where user_id = p_user and household_id = v_h) then
    raise exception 'not_a_member' using errcode = 'P0404';
  end if;
  perform public._leave_household(p_user);
end $$;

-- ---------------------------------------------------------------- plans
-- Fallback / seed plan for a plant, same shape as the AI output {stages, tasks}.
create function public.fallback_plan(p_plant text, p_start start_stage default 'seed') returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_shift int;
  v_first_phase start_stage;
  v_result jsonb;
begin
  select min(phase) into v_first_phase from public.plant_stages
    where plant_id = p_plant and phase >= p_start;
  if v_first_phase is null then return null; end if;
  select min(day_min) - 1 into v_shift from public.plant_stages where plant_id = p_plant and phase >= p_start;
  select jsonb_build_object(
    'stages', coalesce((select jsonb_agg(jsonb_build_object(
                'code', s.code, 'name_vi', s.name_vi, 'name_en', s.name_en,
                'day_from', s.day_min - v_shift, 'day_to', s.day_max - v_shift, 'milestone', s.milestone_code)
                order by s."order")
              from public.plant_stages s where s.plant_id = p_plant and s.phase >= p_start), '[]'),
    'tasks', coalesce((select jsonb_agg(jsonb_build_object(
                'task', d.task_code, 'stage', d.stage_code, 'every_d', d.every_d, 'window', d."window",
                'offset_d', d.offset_d, 'why', d.reason_code)
                order by s."order", d.task_code)
              from public.plant_default_tasks d join public.plant_stages s on s.plant_id = d.plant_id and s.code = d.stage_code
              where d.plant_id = p_plant and s.phase >= p_start), '[]'))
  into v_result;
  return v_result;
end $$;

-- Service role only: persist a validated plan as a new draft.
create function public.create_draft_plan(p_project uuid, p_source plan_source, p_confidence numeric, p_template_key text,
                                         p_model text, p_stages jsonb, p_tasks jsonb)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_plan uuid;
  v_version int;
  s jsonb;
  tk jsonb;
  v_idx int := 0;
  v_stage uuid;
  v_every int;
begin
  select coalesce(max(version), 0) + 1 into v_version from public.plans where project_id = p_project;
  update public.plans set status = 'superseded' where project_id = p_project and status = 'draft';
  insert into public.plans(project_id, version, source, confidence, model, status)
  values (p_project, v_version, p_source, p_confidence, p_model, 'draft') returning id into v_plan;

  for s in select * from jsonb_array_elements(p_stages) loop
    v_idx := v_idx + 1;
    insert into public.stages(plan_id, idx, code, name, name_en, day_from, day_to, milestone_code)
    values (v_plan, v_idx, s->>'code', coalesce(s->>'name_vi', s->>'code'), s->>'name_en',
            (s->>'day_from')::int, (s->>'day_to')::int, nullif(s->>'milestone', ''));
  end loop;

  for tk in select * from jsonb_array_elements(p_tasks) loop
    select id into v_stage from public.stages where plan_id = v_plan and code = tk->>'stage';
    v_every := coalesce((tk->>'every_d')::int, 0);
    insert into public.tasks(project_id, stage_id, task_code, reason_code, "window", frequency, interval_days, day_offset,
                             reminder_time, source)
    values (p_project, v_stage, tk->>'task', nullif(tk->>'why', ''),
            coalesce(nullif(tk->>'window', '')::task_window, 'morning'),
            case when v_every = 0 then 'once' when v_every = 1 then 'daily' else 'every_n_days' end::frequency,
            case when v_every > 1 then v_every end,
            coalesce((tk->>'offset_d')::int, 0),
            nullif(tk->>'reminder', '')::time,
            case p_source when 'ai' then 'ai' else 'template' end::task_source);
  end loop;

  update public.projects set template_key = coalesce(p_template_key, template_key) where id = p_project;
  return v_plan;
end $$;

create function public.approve_plan(p_plan uuid) returns int
language plpgsql security definer set search_path = public as $$
declare
  v_project uuid := public.plan_project(p_plan);
begin
  if v_project is null or not public.can_manage_project(v_project) then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  update public.plans set status = 'superseded' where project_id = v_project and status = 'approved' and id <> p_plan;
  update public.plans set status = 'approved', approved_at = now() where id = p_plan;
  update public.projects set status = 'active' where id = v_project and status <> 'archived';
  return public.materialize_occurrences(v_project, current_date, current_date + 14);
end $$;

-- ---------------------------------------------------------------- apply approved check-in changes (CHK-05)
create function public.apply_checkin_changes(p_checkin uuid, p_accepted uuid[]) returns int
language plpgsql security definer set search_path = public as $$
declare
  c public.checkins%rowtype;
  ch public.checkin_changes%rowtype;
  v_plan uuid;
  v_stage uuid;
  v_applied int := 0;
  v_every int;
  v_start date;
  v_delta int;
  v_idx int;
  v_days int;
begin
  select * into c from public.checkins where id = p_checkin;
  if not found or not public.can_access_project(c.project_id)
     or not (c.user_id = auth.uid() or public.can_manage_project(c.project_id)) then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  select id into v_plan from public.plans where project_id = c.project_id and status = 'approved';
  select start_date into v_start from public.projects where id = c.project_id;

  for ch in select * from public.checkin_changes where checkin_id = p_checkin and accepted = false
            and id = any(coalesce(p_accepted, '{}')) loop
    select id into v_stage from public.stages where plan_id = v_plan and code = ch.payload->>'stage';
    v_every := nullif(ch.payload->>'every_d', '')::int;
    if ch.change_kind = 'add' then
      insert into public.tasks(project_id, stage_id, task_code, reason_code, "window", frequency, interval_days, source)
      select c.project_id, v_stage, tc.code, nullif(ch.payload->>'why', ''),
             coalesce(nullif(ch.payload->>'window','')::task_window, tc.default_window),
             case when coalesce(v_every, tc.default_interval_days, 0) = 0 then 'once'
                  when coalesce(v_every, tc.default_interval_days) = 1 then 'daily' else 'every_n_days' end::frequency,
             case when coalesce(v_every, tc.default_interval_days, 0) > 1 then coalesce(v_every, tc.default_interval_days) end,
             'ai'
      from public.task_codes tc where tc.code = ch.payload->>'task';
    elsif ch.change_kind = 'remove' then
      update public.tasks set status = 'archived'
        where project_id = c.project_id and task_code = ch.payload->>'task' and status = 'active';
    elsif ch.change_kind = 'change_freq' then
      update public.tasks set frequency = case when v_every = 1 then 'daily' else 'every_n_days' end::frequency,
                              interval_days = case when v_every > 1 then v_every end,
                              reason_code = coalesce(nullif(ch.payload->>'why',''), reason_code)
        where project_id = c.project_id and task_code = ch.payload->>'task' and status = 'active';
    elsif ch.change_kind = 'shift' then
      select idx, day_to into v_idx, v_days from public.stages where plan_id = v_plan and milestone_code = ch.payload->>'milestone';
      if v_idx is not null then
        v_delta := ((ch.payload->>'to')::date - v_start + 1) - v_days;
        update public.stages set day_to = day_to + v_delta where plan_id = v_plan and idx = v_idx and day_to + v_delta >= day_from;
        update public.stages set day_from = day_from + v_delta, day_to = day_to + v_delta
          where plan_id = v_plan and idx > v_idx and day_from + v_delta >= 1;
      end if;
    end if;
    update public.checkin_changes set accepted = true where id = ch.id;
    v_applied := v_applied + 1;
  end loop;

  update public.checkins set status = case when v_applied > 0 then 'approved' else 'rejected' end::checkin_status
    where id = p_checkin and status = 'analyzed';

  if v_applied > 0 then
    -- rebuild future occurrences from the changed plan
    delete from public.task_occurrences where project_id = c.project_id and due_date >= current_date and state = 'pending';
    perform public.materialize_occurrences(c.project_id, current_date, current_date + 14);
  end if;
  return v_applied;
end $$;

-- ---------------------------------------------------------------- account deletion
create function public.account_storage_paths(p_user uuid) returns table(bucket text, path text)
language sql stable security definer set search_path = public as $$
  select 'checkins', s->>'path' from public.checkins c, jsonb_array_elements(c.shots) s
    where c.user_id = p_user and s->>'path' is not null
  union all select 'checkins', l.photo_path from public.task_logs l where l.user_id = p_user and l.photo_path is not null
  union all select 'avatars', u.avatar_path from public.users u where u.id = p_user and u.avatar_path is not null
  union all select 'checkins', p.cover_path from public.projects p where p.owner_id = p_user and p.cover_path is not null
  union all select 'checkins', s->>'path' from public.checkins c join public.projects p on p.id = c.project_id,
            jsonb_array_elements(c.shots) s where p.owner_id = p_user and s->>'path' is not null
$$;

-- Deletes all data of the caller, then the auth identity. Storage files are removed by the delete-account
-- Edge Function first (direct SQL deletes on storage.objects are blocked by Supabase).
create function public.delete_my_account() returns void
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  perform public._leave_household(v_uid);
  delete from public.users where id = v_uid;      -- cascades projects, logs, checkins, xp, badges, lessons ...
  delete from auth.users where id = v_uid;
end $$;

-- ---------------------------------------------------------------- misc client RPCs
create function public.my_streak() returns int
language sql stable security definer set search_path = public as $$ select public.user_streak(auth.uid()) $$;

-- ---------------------------------------------------------------- privileges
revoke all on function
  public.award_xp(uuid, uuid, xp_source, uuid, int, timestamptz),
  public.evaluate_badges(uuid),
  public.user_streak(uuid),
  public.log_activity(uuid, uuid, text, uuid, jsonb),
  public._leave_household(uuid),
  public.ai_quota_refund(uuid, ai_kind),
  public.ai_usage_record(uuid, ai_kind, text, int, int, int, numeric),
  public.create_draft_plan(uuid, plan_source, numeric, text, text, jsonb, jsonb),
  public.account_storage_paths(uuid),
  public.task_due_on(uuid, date)
  from public, anon, authenticated;

grant execute on function
  public.search_plants(text, plant_group, int),
  public.vn_normalize(text), public.vn_search_key(text),
  public.fallback_plan(text, start_stage),
  public.materialize_occurrences(uuid, date, date),
  public.consume_ai_quota(ai_kind), public.get_ai_quota(),
  public.create_household(text), public.create_invite(invite_channel, text, member_role), public.revoke_invite(uuid),
  public.accept_invite(text), public.leave_household(), public.remove_member(uuid),
  public.approve_plan(uuid), public.apply_checkin_changes(uuid, uuid[]),
  public.delete_my_account(), public.my_streak()
  to authenticated;
-- RLS helper functions are called from policies as the invoking role.
grant execute on function
  public.is_household_member(uuid), public.is_household_owner(uuid), public.my_household_id(),
  public.shares_household_with(uuid), public.can_access_project(uuid), public.can_manage_project(uuid),
  public.plan_project(uuid), public.checkin_project(uuid), public.safe_uuid(text), public.user_local_date(uuid, timestamptz),
  public.cfg_int(text, int), public.level_for_xp(int)
  to authenticated;
