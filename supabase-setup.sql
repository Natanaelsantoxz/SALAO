-- Cole tudo isto no Supabase: SQL Editor > New query > Run

create table settings (
  id int primary key default 1 check (id = 1),
  name text default 'Meu Studio',
  tagline text default 'Escolha a profissional e reserve seu horário',
  whatsapp text default '5519999999999',
  open_time text default '09:00',
  close_time text default '18:00'
);
insert into settings default values;

create table professionals (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  specialty text,
  created_at timestamptz default now()
);

create table services (
  id uuid primary key default gen_random_uuid(),
  professional_id uuid references professionals(id) on delete cascade,
  name text not null,
  price numeric default 0
);

create table appointments (
  id uuid primary key default gen_random_uuid(),
  professional_id uuid references professionals(id) on delete cascade,
  service_name text,
  client_name text not null,
  client_phone text not null,
  date date not null,
  time text not null,
  status text default 'pendente',
  created_at timestamptz default now()
);
create unique index one_booking_per_slot on appointments (professional_id, date, time) where status <> 'cancelado';

alter table settings enable row level security;
alter table professionals enable row level security;
alter table services enable row level security;
alter table appointments enable row level security;

-- Clientes (público): só leem o catálogo e criam agendamentos
create policy "ler settings" on settings for select using (true);
create policy "ler profissionais" on professionals for select using (true);
create policy "ler servicos" on services for select using (true);
create policy "criar agendamento" on appointments for insert with check (status = 'pendente');

-- Você (logada): controle total
create policy "admin settings" on settings for all to authenticated using (true) with check (true);
create policy "admin profissionais" on professionals for all to authenticated using (true) with check (true);
create policy "admin servicos" on services for all to authenticated using (true) with check (true);
create policy "admin agendamentos" on appointments for all to authenticated using (true) with check (true);

-- Horários ocupados, sem expor dados das clientes
create function busy_times(p uuid, d date) returns table(t text)
language sql security definer as $$
  select time from appointments where professional_id = p and date = d and status <> 'cancelado';
$$;
grant execute on function busy_times(uuid, date) to anon, authenticated;

-- Depois: Authentication > Users > Add user (seu e-mail e senha) para entrar no painel.
