-- Gestiones Express · esquema de producción con acceso de administrador explícito.
-- La migración equivalente ya fue aplicada al proyecto Supabase.
create table if not exists public.servicios (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  descripcion text not null default '',
  precio text not null default 'Consultar',
  tiempo_entrega text not null default '24-48 horas',
  requisitos jsonb not null default '[]'::jsonb,
  imagen text not null default '',
  activo boolean not null default true,
  clicks integer not null default 0 check (clicks >= 0),
  created_at timestamptz not null default now()
);
create table if not exists public.config (clave text primary key, valor text not null);
insert into public.config (clave, valor) values ('whatsapp','') on conflict (clave) do nothing;
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.servicios enable row level security;
alter table public.config enable row level security;
alter table public.admin_users enable row level security;
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;
create or replace function private.is_admin() returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.admin_users a where a.user_id = (select auth.uid()));
$$;
revoke all on function private.is_admin() from public, anon;
grant execute on function private.is_admin() to authenticated;
-- Drop/recreate these named policies for repeatable installation.
drop policy if exists servicios_public_read_active on public.servicios;
drop policy if exists servicios_admin_read_all on public.servicios;
drop policy if exists servicios_anon_read_active on public.servicios;
drop policy if exists servicios_authenticated_read on public.servicios;
create policy servicios_anon_read_active on public.servicios for select to anon using (activo = true);
create policy servicios_authenticated_read on public.servicios for select to authenticated using (activo = true or (select private.is_admin()));
drop policy if exists servicios_admin_insert on public.servicios;
create policy servicios_admin_insert on public.servicios for insert to authenticated with check ((select private.is_admin()));
drop policy if exists servicios_admin_update on public.servicios;
create policy servicios_admin_update on public.servicios for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
drop policy if exists servicios_admin_delete on public.servicios;
create policy servicios_admin_delete on public.servicios for delete to authenticated using ((select private.is_admin()));
drop policy if exists config_public_whatsapp_read on public.config;
create policy config_public_whatsapp_read on public.config for select to anon, authenticated using (clave = 'whatsapp');
drop policy if exists config_admin_insert on public.config;
create policy config_admin_insert on public.config for insert to authenticated with check ((select private.is_admin()));
drop policy if exists config_admin_update on public.config;
create policy config_admin_update on public.config for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
drop policy if exists config_admin_delete on public.config;
create policy config_admin_delete on public.config for delete to authenticated using ((select private.is_admin()));
drop policy if exists admin_users_read_self on public.admin_users;
create policy admin_users_read_self on public.admin_users for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists servicios_anon_increment_click on public.servicios;
create policy servicios_anon_increment_click on public.servicios for update to anon using (activo = true) with check (activo = true);
create or replace function private.enforce_public_click_increment() returns trigger language plpgsql set search_path = '' as $$
begin
  if current_user = 'anon' and new.clicks <> old.clicks + 1 then
    raise exception 'Public click updates may only increment the counter by one';
  end if;
  return new;
end;
$$;
drop trigger if exists enforce_public_click_increment on public.servicios;
create trigger enforce_public_click_increment before update of clicks on public.servicios for each row execute function private.enforce_public_click_increment();
revoke all on table public.servicios from public, anon, authenticated;
revoke all on table public.config from public, anon, authenticated;
revoke all on table public.admin_users from public, anon, authenticated;
grant select on table public.servicios to anon, authenticated;
grant update (clicks) on table public.servicios to anon;
grant insert, update, delete on table public.servicios to authenticated;
grant select on table public.config to anon, authenticated;
grant insert, update, delete on table public.config to authenticated;
grant select on table public.admin_users to authenticated;
create or replace function public.contar_click(servicio_id uuid) returns void language sql security invoker set search_path = '' as $$
  update public.servicios set clicks = clicks + 1 where id = $1 and activo = true;
$$;
revoke all on function public.contar_click(uuid) from public;
grant execute on function public.contar_click(uuid) to anon, authenticated;
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('servicios','servicios',true,5242880,array['image/jpeg','image/png','image/webp','image/gif']) on conflict (id) do nothing;
drop policy if exists servicios_images_public_read on storage.objects;
create policy servicios_images_public_read on storage.objects for select to anon, authenticated using (bucket_id = 'servicios');
drop policy if exists servicios_images_admin_insert on storage.objects;
create policy servicios_images_admin_insert on storage.objects for insert to authenticated with check (bucket_id = 'servicios' and (select private.is_admin()));
drop policy if exists servicios_images_admin_update on storage.objects;
create policy servicios_images_admin_update on storage.objects for update to authenticated using (bucket_id = 'servicios' and (select private.is_admin())) with check (bucket_id = 'servicios' and (select private.is_admin()));
drop policy if exists servicios_images_admin_delete on storage.objects;
create policy servicios_images_admin_delete on storage.objects for delete to authenticated using (bucket_id = 'servicios' and (select private.is_admin()));
-- Después de crear un usuario en Authentication, autorízalo insertando su UUID:
-- insert into public.admin_users(user_id) values ('UUID_DEL_USUARIO');
