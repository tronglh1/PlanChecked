-- QA round 2 fixes (never edit applied migrations: this one only adds / replaces).
--  * stronger invite codes: 'VUON-' + 6 chars from an unambiguous alphabet (31^6 ~ 8.9e8 combinations)
--  * server-side push: trigger functions that call the `send-push` Edge Function through pg_net

-- ---------------------------------------------------------------- invite codes
-- Alphabet: A-Z without I, L, O plus 2-9 (no 0/1), so codes survive being read aloud or typed from a screenshot.
-- Legacy 'VUON-1234' invites that are still pending keep working (accept_invite matches the stored code).
-- Rate limits are unchanged: 10 failed accept attempts per user per hour, 20 invites per household per day.
create or replace function public.create_invite(p_channel invite_channel default 'code', p_target text default null,
                                                p_role member_role default 'member')
returns public.invites
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_h uuid;
  v_code text;
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  i public.invites;
  v_try int := 0;
begin
  select m.household_id into v_h from public.household_members m where m.user_id = v_uid and m.role = 'owner';
  if v_h is null then raise exception 'not_household_owner' using errcode = '42501'; end if;
  if (select count(*) from public.invites where household_id = v_h and created_at > now() - interval '1 day') >= 20 then
    raise exception 'too_many_invites' using errcode = 'P0429';
  end if;
  loop
    v_code := 'VUON-';
    for k in 1..6 loop
      v_code := v_code || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from public.invites where code = v_code and status = 'pending');
    v_try := v_try + 1;
    if v_try > 50 then raise exception 'no_code_available'; end if;
  end loop;
  insert into public.invites(household_id, code, channel, target, role, created_by)
  values (v_h, v_code, p_channel, nullif(trim(p_target), ''), p_role, v_uid) returning * into i;
  return i;
end $$;

-- ---------------------------------------------------------------- push triggers
-- pg_net issues the HTTP call after commit. Not available in the PGlite test database, hence the guarded block.
do $$ begin
  create extension if not exists pg_net;
exception when others then
  raise notice 'pg_net not installed (%); push triggers stay inert until it is', sqlerrm;
end $$;

-- Server-only settings (url + shared secret of the send-push function). RLS on and no policy: only
-- security-definer functions and the service role can read it.
create table public.private_config (
  key        text primary key,
  value      text not null,
  updated_at timestamptz not null default now()
);
alter table public.private_config enable row level security;
revoke all on public.private_config from anon, authenticated;

-- Body mirrors Supabase Database Webhooks ({type, table, schema, record, old_record}) plus `actor_id`
-- (the user who caused the change; the sender never notifies the actor about their own action).
-- Never raises: a push problem must not roll back the user's write.
create function public.push_dispatch(p_table text, p_op text, p_record jsonb, p_old jsonb, p_actor uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_url text;
  v_secret text;
begin
  select value into v_url from public.private_config where key = 'push_function_url';
  select value into v_secret from public.private_config where key = 'push_webhook_secret';
  if v_url is null or v_secret is null then return; end if;
  perform net.http_post(
    url := v_url,
    body := jsonb_build_object('type', p_op, 'table', p_table, 'schema', 'public',
                               'record', p_record, 'old_record', p_old, 'actor_id', p_actor),
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-webhook-secret', v_secret)
  );
exception when others then
  raise warning 'push_dispatch failed: %', sqlerrm;
end $$;
revoke all on function public.push_dispatch(text, text, jsonb, jsonb, uuid) from public, anon, authenticated;

create function public.tasks_push_assignment() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.assignee_id is not null
     and (tg_op = 'INSERT' or old.assignee_id is distinct from new.assignee_id)
     and new.assignee_id is distinct from auth.uid() then
    perform public.push_dispatch('tasks', tg_op, to_jsonb(new),
                                 case when tg_op = 'UPDATE' then to_jsonb(old) end, auth.uid());
  end if;
  return new;
end $$;
create trigger tasks_push_assignment after insert or update of assignee_id on public.tasks
  for each row execute function public.tasks_push_assignment();

create function public.user_badges_push() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.push_dispatch('user_badges', 'INSERT', to_jsonb(new), null, null);
  return new;
end $$;
create trigger user_badges_push after insert on public.user_badges
  for each row execute function public.user_badges_push();

create function public.household_activity_push() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.push_dispatch('household_activity', 'INSERT', to_jsonb(new), null, new.actor_id);
  return new;
end $$;
create trigger household_activity_push after insert on public.household_activity
  for each row execute function public.household_activity_push();
