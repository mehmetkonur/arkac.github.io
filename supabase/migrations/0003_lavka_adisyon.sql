-- ════════════════════════════════════════════════════════════════════
-- LAVKA — MASA ADİSYONLARI (POS)
-- Masa hesabı: açılır, kalemler eklenir, mutfağa gönderilen kalemler
-- lavka_siparis kaydına dönüşür, ödeme alınınca kapanır.
-- Yalnızca personel erişir; misafir tarafı bu tabloları görmez.
-- ════════════════════════════════════════════════════════════════════

create table if not exists lavka_masa(
  id       text primary key,          -- S1, T3, B2 …
  ad       text not null,
  kat      text not null,             -- Salon / Teras / Bar Tezgâhı
  kisi     int  not null default 4 check (kisi between 1 and 30),
  sira     int  not null default 0,
  aktif    boolean not null default true,
  rezerve  timestamptz                -- doluysa rezervasyon zamanı
);

create sequence if not exists lavka_adisyon_seq start 1;

create table if not exists lavka_adisyon(
  id         uuid primary key default gen_random_uuid(),
  no         int not null default nextval('lavka_adisyon_seq'),
  masa_id    text not null references lavka_masa(id),
  kisi       int not null default 1,
  garson     text not null default '',
  kalemler   jsonb not null default '[]'::jsonb,  -- [{id,ad,fiyat,sure,istasyon,adet,ikram,gonderildi}]
  indirim_yuzde numeric(5,2) not null default 0 check (indirim_yuzde between 0 and 100),
  durum      text not null default 'acik' check (durum in ('acik','kapali')),
  odeme      text not null default '' check (odeme in ('','nakit','kart','online','iptal')),
  toplam     numeric(10,2) not null default 0,
  siparis_kodlari text[] not null default '{}',
  acilis     timestamptz not null default now(),
  kapanis    timestamptz,
  guncelleme timestamptz not null default now()
);
create index if not exists lavka_adisyon_masa_ix on lavka_adisyon (masa_id) where durum = 'acik';
create index if not exists lavka_adisyon_tarih_ix on lavka_adisyon (acilis desc);

-- Bir masada aynı anda tek açık adisyon
create unique index if not exists lavka_adisyon_tek_acik on lavka_adisyon (masa_id) where durum = 'acik';

-- Siparişi adisyona bağla (mutfak fişi hangi hesaptan geldi)
alter table lavka_siparis add column if not exists adisyon_id uuid references lavka_adisyon(id);

alter table lavka_masa    enable row level security;
alter table lavka_adisyon enable row level security;

drop policy if exists "masa_personel"    on lavka_masa;
drop policy if exists "adisyon_personel" on lavka_adisyon;

create policy "masa_personel" on lavka_masa
  for all to authenticated using (lavka_personel_mi()) with check (lavka_personel_mi());
create policy "adisyon_personel" on lavka_adisyon
  for all to authenticated using (lavka_personel_mi()) with check (lavka_personel_mi());

-- QR menüden gelen misafir siparişinin masasını doğrulamak için
-- (kişisel veri içermez: yalnızca masa adı ve katı)
create or replace function lavka_masalar()
returns table(id text, ad text, kat text, kisi int)
language sql stable security definer set search_path = public as $$
  select m.id, m.ad, m.kat, m.kisi from lavka_masa m where m.aktif order by m.sira, m.id;
$$;
grant execute on function lavka_masalar() to anon, authenticated;

do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and tablename = 'lavka_adisyon') then
    alter publication supabase_realtime add table lavka_adisyon;
  end if;
end $$;

-- Masalar (lavka.html içindeki KATLAR tanımından üretildi)
insert into lavka_masa (id, ad, kat, kisi, sira) values
  ('S1', 'Salon 1', 'Salon', 4, 10),
  ('S2', 'Salon 2', 'Salon', 4, 20),
  ('S3', 'Salon 3', 'Salon', 2, 30),
  ('S4', 'Salon 4', 'Salon', 2, 40),
  ('S5', 'Salon 5', 'Salon', 6, 50),
  ('S6', 'Salon 6', 'Salon', 4, 60),
  ('S7', 'Salon 7', 'Salon', 4, 70),
  ('S8', 'Salon 8', 'Salon', 2, 80),
  ('S9', 'Salon 9', 'Salon', 2, 90),
  ('S10', 'Salon 10', 'Salon', 4, 100),
  ('S11', 'Salon 11', 'Salon', 4, 110),
  ('S12', 'Salon 12', 'Salon', 6, 120),
  ('T1', 'Teras 1', 'Teras', 4, 130),
  ('T2', 'Teras 2', 'Teras', 4, 140),
  ('T3', 'Teras 3', 'Teras', 2, 150),
  ('T4', 'Teras 4', 'Teras', 2, 160),
  ('T5', 'Teras 5', 'Teras', 6, 170),
  ('T6', 'Teras 6', 'Teras', 4, 180),
  ('B1', 'Tezgâh 1', 'Bar Tezgâhı', 1, 190),
  ('B2', 'Tezgâh 2', 'Bar Tezgâhı', 1, 200),
  ('B3', 'Tezgâh 3', 'Bar Tezgâhı', 1, 210),
  ('B4', 'Tezgâh 4', 'Bar Tezgâhı', 1, 220),
  ('B5', 'Tezgâh 5', 'Bar Tezgâhı', 1, 230),
  ('B6', 'Tezgâh 6', 'Bar Tezgâhı', 1, 240)
on conflict (id) do update set ad = excluded.ad, kat = excluded.kat,
  kisi = excluded.kisi, sira = excluded.sira;
