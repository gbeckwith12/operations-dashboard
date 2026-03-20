begin;

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.systems (
  id text primary key,
  name text not null unique,
  status text not null default 'Active',
  note text,
  icon text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.service_impacts (
  id text primary key,
  system text not null,
  title text not null,
  impact_type text not null,
  severity text not null,
  status text not null default 'Investigating',
  member_impact text not null,
  internal_impact text,
  owner text,
  audience text not null default 'Members',
  publish_externally boolean not null default false,
  summary text,
  source_type text default 'Manual Summary',
  source_detail text,
  started_at timestamptz not null default now(),
  deactivate_at timestamptz,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint service_impacts_severity_check check (severity in ('Critical','High','Medium','Low')),
  constraint service_impacts_status_check check (status in ('Investigating','Identified','Monitoring','Resolved','Closed')),
  constraint service_impacts_audience_check check (audience in ('Members','Staff','Both'))
);

create table if not exists public.maintenance (
  id text primary key,
  system text not null,
  title text not null,
  status text not null default 'Planned',
  owner text,
  summary text not null,
  start_at timestamptz,
  end_at timestamptz,
  deactivate_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint maintenance_status_check check (status in ('Planned','Active','Monitoring','Complete'))
);

create table if not exists public.enhancements (
  id text primary key,
  system text not null,
  title text not null,
  stage text not null default 'Intake',
  dept text,
  aud text,
  sum text not null,
  impact text,
  timing text,
  deactivate_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint enhancements_stage_check check (stage in ('Intake','Review','Approved','Planned','In Progress','Complete','Archived'))
);

create table if not exists public.releases (
  id text primary key,
  system text not null,
  title text not null,
  status text not null default 'Planned',
  summary text not null,
  target_date timestamptz,
  deactivate_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint releases_status_check check (status in ('Planned','In Progress','Complete','Archived'))
);

drop trigger if exists trg_systems_updated_at on public.systems;
create trigger trg_systems_updated_at
before update on public.systems
for each row execute function public.set_updated_at();

drop trigger if exists trg_service_impacts_updated_at on public.service_impacts;
create trigger trg_service_impacts_updated_at
before update on public.service_impacts
for each row execute function public.set_updated_at();

drop trigger if exists trg_maintenance_updated_at on public.maintenance;
create trigger trg_maintenance_updated_at
before update on public.maintenance
for each row execute function public.set_updated_at();

drop trigger if exists trg_enhancements_updated_at on public.enhancements;
create trigger trg_enhancements_updated_at
before update on public.enhancements
for each row execute function public.set_updated_at();

drop trigger if exists trg_releases_updated_at on public.releases;
create trigger trg_releases_updated_at
before update on public.releases
for each row execute function public.set_updated_at();

insert into public.systems (id, name, status, note, icon)
values (
  'enterprise-multi-system',
  'Enterprise / Multi-System',
  'Active',
  'Fallback system for cross-system or legacy records.',
  '🧩'
)
on conflict (id) do nothing;

commit;
