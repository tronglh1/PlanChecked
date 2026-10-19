-- QA round 1 fixes (new migration; earlier migrations are already applied).

-- C2: a household Member may create (and keep) projects inside their own household,
-- not only the household Owner. Sharing an existing private project is done the same
-- way (set household_id to one's own household); managing OTHER people's projects
-- still requires the household Owner role (can_manage_project).
drop policy projects_insert on public.projects;
create policy projects_insert on public.projects for insert to authenticated
  with check (owner_id = (select auth.uid()) and (household_id is null or public.is_household_member(household_id)));

drop policy projects_update on public.projects;
create policy projects_update on public.projects for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()) and (household_id is null or public.is_household_member(household_id)));

-- C12: project cover upload uses upsert, which needs UPDATE on the object.
create policy checkins_objects_update on storage.objects for update to authenticated
  using (bucket_id = 'checkins' and owner_id = (select auth.uid())::text)
  with check (bucket_id = 'checkins' and public.checkin_path_ok(name) and lower(name) like '%.jpg');
