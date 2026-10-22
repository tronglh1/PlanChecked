-- Vườn Nhà: Row Level Security on every table.
-- Rule: a row is visible to its owner, or to members of the household the project is shared with.
-- Owner role (household) can manage shared projects/plans/tasks/assignments; Member can view and Done/Skip/Snooze.
-- Server-owned writes (XP, usage, occurrences, plans from AI, household membership) go through SECURITY DEFINER
-- functions or the service role; there is deliberately no client write policy for those tables.

do $$
declare t text;
begin
  for t in select tablename from pg_tables where schemaname = 'public' loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- ---------------------------------------------------------------- reference / content (read-only for clients)
do $$
declare t text;
begin
  foreach t in array array['app_config','levels','plants','plant_stages','task_codes','reason_codes','milestone_codes',
                           'problem_codes','plant_problems','plant_default_tasks','text_templates','plan_templates',
                           'badges_catalog']
  loop
    execute format('create policy %I on public.%I for select to authenticated using (true)', t || '_read', t);
  end loop;
end $$;

-- ---------------------------------------------------------------- users
create policy users_select_self on public.users for select to authenticated
  using (id = (select auth.uid()));
create policy users_update_self on public.users for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
-- insert happens in the auth.users trigger; delete via delete_my_account()

-- Household peers see only name, avatar, level and xp of each other.
create view public.member_profiles with (security_invoker = false) as
  select u.id, u.display_name, u.avatar_path, u.level, u.xp_total
  from public.users u
  where u.id = auth.uid() or public.shares_household_with(u.id);
grant select on public.member_profiles to authenticated;

-- ---------------------------------------------------------------- household
create policy households_select on public.households for select to authenticated
  using (public.is_household_member(id) or owner_id = (select auth.uid()));
create policy households_update_owner on public.households for update to authenticated
  using (public.is_household_owner(id)) with check (public.is_household_owner(id));

create policy household_members_select on public.household_members for select to authenticated
  using (public.is_household_member(household_id));

create policy invites_select_owner on public.invites for select to authenticated
  using (public.is_household_owner(household_id));

create policy household_activity_select on public.household_activity for select to authenticated
  using (public.is_household_member(household_id));

-- ---------------------------------------------------------------- projects and plans
create policy projects_select on public.projects for select to authenticated
  using (owner_id = (select auth.uid()) or (household_id is not null and public.is_household_member(household_id)));
create policy projects_insert on public.projects for insert to authenticated
  with check (owner_id = (select auth.uid()) and (household_id is null or public.is_household_owner(household_id)));
create policy projects_update on public.projects for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()) and (household_id is null or public.is_household_owner(household_id)));
create policy projects_delete on public.projects for delete to authenticated
  using (owner_id = (select auth.uid()));

create policy plans_select on public.plans for select to authenticated using (public.can_access_project(project_id));
create policy plans_insert on public.plans for insert to authenticated with check (public.can_manage_project(project_id));
create policy plans_update on public.plans for update to authenticated
  using (public.can_manage_project(project_id)) with check (public.can_manage_project(project_id));
create policy plans_delete on public.plans for delete to authenticated using (public.can_manage_project(project_id));

create policy stages_select on public.stages for select to authenticated
  using (public.can_access_project(public.plan_project(plan_id)));
create policy stages_write on public.stages for all to authenticated
  using (public.can_manage_project(public.plan_project(plan_id)))
  with check (public.can_manage_project(public.plan_project(plan_id)));

create policy tasks_select on public.tasks for select to authenticated using (public.can_access_project(project_id));
create policy tasks_write on public.tasks for all to authenticated
  using (public.can_manage_project(project_id)) with check (public.can_manage_project(project_id));

create policy task_occurrences_select on public.task_occurrences for select to authenticated
  using (public.can_access_project(project_id));

create policy task_logs_select on public.task_logs for select to authenticated using (public.can_access_project(project_id));
-- Done/Skip/Snooze: anyone with access to the project for unassigned tasks or tasks assigned to them;
-- managers may log for anyone's task. user_id is forced to auth.uid() by trigger.
create policy task_logs_insert on public.task_logs for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.tasks t
      where t.id = task_id
        and public.can_access_project(t.project_id)
        and (t.assignee_id is null or t.assignee_id = (select auth.uid()) or public.can_manage_project(t.project_id))));

-- ---------------------------------------------------------------- check-in and AI
create policy checkins_select on public.checkins for select to authenticated using (public.can_access_project(project_id));
create policy checkins_insert on public.checkins for insert to authenticated
  with check (user_id = (select auth.uid()) and public.can_access_project(project_id)
              and status = 'pending' and ai_result is null);
create policy checkins_delete on public.checkins for delete to authenticated using (user_id = (select auth.uid()));

create policy checkin_changes_select on public.checkin_changes for select to authenticated
  using (public.can_access_project(public.checkin_project(checkin_id)));

create policy milestones_select on public.milestones_reached for select to authenticated
  using (public.can_access_project(project_id));
-- manual claim: no checkin attached, so never XP/badge-eligible
create policy milestones_insert_manual on public.milestones_reached for insert to authenticated
  with check (public.can_manage_project(project_id) and confirmed_by = 'user' and checkin_id is null);

create policy project_lessons_all on public.project_lessons for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy ai_usage_select on public.ai_usage for select to authenticated using (user_id = (select auth.uid()));

create policy ai_feedback_select on public.ai_feedback for select to authenticated using (user_id = (select auth.uid()));
create policy ai_feedback_insert on public.ai_feedback for insert to authenticated with check (user_id = (select auth.uid()));

-- ---------------------------------------------------------------- gamification
create policy xp_events_select on public.xp_events for select to authenticated using (user_id = (select auth.uid()));
create policy user_badges_select on public.user_badges for select to authenticated using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------- other
create policy notification_prefs_all on public.notification_prefs for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy push_tokens_all on public.push_tokens for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy consents_select on public.consents for select to authenticated using (user_id = (select auth.uid()));
create policy consents_insert on public.consents for insert to authenticated with check (user_id = (select auth.uid()));

create policy devices_all on public.devices for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy sensor_readings_select on public.sensor_readings for select to authenticated
  using (exists (select 1 from public.devices d where d.id = device_id and d.user_id = (select auth.uid())));
-- readings are written by the (future) ingest function with the service role

-- invite_attempts: no policy at all = no client access.

-- ---------------------------------------------------------------- explicit privileges
-- Supabase grants table privileges to anon/authenticated by default; tighten the server-owned ones so a
-- missing policy is never the only line of defence.
revoke insert, update, delete on
  public.xp_events, public.user_badges, public.ai_usage, public.task_occurrences, public.checkin_changes,
  public.household_members, public.invites, public.household_activity, public.invite_attempts,
  public.app_config, public.levels, public.plants, public.plant_stages, public.task_codes, public.reason_codes,
  public.milestone_codes, public.problem_codes, public.plant_problems, public.plant_default_tasks,
  public.text_templates, public.plan_templates, public.badges_catalog, public.sensor_readings
  from anon, authenticated;
revoke all on public.invite_attempts from anon, authenticated;
revoke all on all tables in schema public from anon;
revoke update on public.checkins from anon, authenticated;
revoke update on public.task_logs from anon, authenticated;
revoke delete on public.task_logs from anon, authenticated;
revoke insert on public.users from anon, authenticated;
revoke delete on public.users from anon, authenticated;
revoke insert, delete on public.households from anon, authenticated;
