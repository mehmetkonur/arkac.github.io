-- ════════════════════════════════════════════════════════════════════
-- LAVKA SİPARİŞ SİSTEMİ — şema, güvenlik (RLS) ve fonksiyonlar
-- Uygulanan proje: lavka.html  (misafir sipariş + bar/fırın + yönetim)
--
-- Güvenlik modeli
--   • Misafir (anon): tablolara doğrudan erişemez. Yalnızca aşağıdaki
--     SECURITY DEFINER fonksiyonlarını çağırır. Sipariş fiyatı ve süresi
--     istemciden ALINMAZ, menüden sunucuda yeniden hesaplanır.
--   • Misafir kendi siparişini yalnızca (kod + takip_token) ikilisiyle
--     görebilir; token rastgele uuid'dir, kod tahmin edilse bile yetmez.
--   • Personel (authenticated + lavka_personel kaydı): tüm siparişleri
--     görür ve durum değiştirir; her değişiklik gecmis alanına kim
--     bilgisiyle yazılır.
-- ════════════════════════════════════════════════════════════════════

create extension if not exists pgcrypto;

-- Sipariş kodu sayacı: LV-100, LV-101 …
create sequence if not exists lavka_kod_seq start 100;

-- ───────────────────────── MENÜ ─────────────────────────
create table if not exists lavka_menu(
  id         text primary key,
  kategori   text not null,
  ad         text not null,
  aciklama   text not null default '',
  fiyat      numeric(10,2) not null check (fiyat >= 0),
  sure       int  not null check (sure between 1 and 180),   -- dakika
  ikon       text not null default '',
  istasyon   text not null check (istasyon in ('bar','firin')),
  satista    boolean not null default true,
  sira       int not null default 0,
  guncelleme timestamptz not null default now()
);
comment on table lavka_menu is 'Lavka ürün menüsü; fiyat ve hazırlık süresinin tek doğru kaynağı.';

-- ─────────────────────── PERSONEL ───────────────────────
create table if not exists lavka_personel(
  user_id   uuid primary key references auth.users(id) on delete cascade,
  ad        text not null,
  rol       text not null default 'ekip' check (rol in ('ekip','yonetim')),
  aktif     boolean not null default true,
  olusturma timestamptz not null default now()
);
comment on table lavka_personel is 'Ekip ekranlarına erişebilen Supabase kullanıcıları.';

-- ──────────────────────── SİPARİŞ ───────────────────────
create table if not exists lavka_siparis(
  id            uuid primary key default gen_random_uuid(),
  kod           text unique not null,
  takip_token   uuid not null default gen_random_uuid(),
  ad            text not null,
  tel           text not null default '',
  tip           text not null check (tip in ('masa','gelal','magaza')),
  masa          text not null default '',
  magaza        text not null default '',
  kat           text not null default '',
  siparis_notu  text not null default '',
  odeme         text not null default 'online' check (odeme in ('online','kart','nakit')),
  kalemler      jsonb not null,                 -- [{id,ad,fiyat,sure,istasyon,adet}]
  ara_toplam    numeric(10,2) not null,
  servis        numeric(10,2) not null default 0,
  toplam        numeric(10,2) not null,
  durum         text not null default 'yeni'
                check (durum in ('yeni','onay','hazirlik','hazir','yolda','teslim','iptal')),
  soz_dk        int not null,                   -- söz verilen süre (dk)
  ek_sure       int not null default 0,         -- sonradan uzatılan süre (dk)
  kurye         text not null default '',
  iptal_sebep   text not null default '',
  puan          int check (puan between 1 and 5),
  t_yeni        timestamptz not null default now(),
  t_onay        timestamptz,
  t_hazirlik    timestamptz,
  t_hazir       timestamptz,
  t_yolda       timestamptz,
  t_teslim      timestamptz,
  t_iptal       timestamptz,
  gecmis        jsonb not null default '[]'::jsonb,
  guncelleme    timestamptz not null default now()
);
create index if not exists lavka_siparis_durum_ix on lavka_siparis (durum, t_yeni desc);
create index if not exists lavka_siparis_tarih_ix on lavka_siparis (t_yeni desc);
comment on table lavka_siparis is 'Siparişler; süreç adımlarının zaman damgaları ve gecmis günlüğü ile.';

-- ─────────────────── YARDIMCI FONKSİYONLAR ──────────────
create or replace function lavka_personel_mi() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from lavka_personel p where p.user_id = auth.uid() and p.aktif);
$$;

create or replace function lavka_personel_adi() returns text
language sql stable security definer set search_path = public as $$
  select coalesce((select p.ad from lavka_personel p where p.user_id = auth.uid()), 'Ekip');
$$;

-- ──────────────────── SATIR GÜVENLİĞİ ───────────────────
alter table lavka_menu     enable row level security;
alter table lavka_personel enable row level security;
alter table lavka_siparis  enable row level security;

drop policy if exists "menu_okuma_herkes"     on lavka_menu;
drop policy if exists "menu_yazma_personel"   on lavka_menu;
drop policy if exists "personel_okuma"        on lavka_personel;
drop policy if exists "siparis_okuma_personel" on lavka_siparis;
drop policy if exists "siparis_yazma_personel" on lavka_siparis;

create policy "menu_okuma_herkes" on lavka_menu
  for select to anon, authenticated using (true);
create policy "menu_yazma_personel" on lavka_menu
  for all to authenticated using (lavka_personel_mi()) with check (lavka_personel_mi());

create policy "personel_okuma" on lavka_personel
  for select to authenticated using (user_id = auth.uid() or lavka_personel_mi());

-- Siparişlerde anon için HİÇBİR politika yok: erişim sadece fonksiyonlarla.
create policy "siparis_okuma_personel" on lavka_siparis
  for select to authenticated using (lavka_personel_mi());
create policy "siparis_yazma_personel" on lavka_siparis
  for update to authenticated using (lavka_personel_mi()) with check (lavka_personel_mi());

-- ═════════════════ MİSAFİR FONKSİYONLARI ════════════════

-- Sipariş oluştur: fiyat/süre menüden alınır, istemciye güvenilmez.
create or replace function lavka_siparis_olustur(
  p_kalemler jsonb, p_tip text, p_ad text, p_tel text default '',
  p_masa text default '', p_magaza text default '', p_kat text default '',
  p_not text default '', p_odeme text default 'online')
returns table(kod text, takip_token uuid, soz_dk int, toplam numeric, t_yeni timestamptz)
language plpgsql security definer set search_path = public as $$
declare
  v_kalemler jsonb; v_ara numeric := 0; v_enuzun int := 0; v_adet int := 0;
  v_soz int; v_servis numeric := 0; v_kod text; v_kuyruk int; v_ad text;
begin
  v_ad := btrim(coalesce(p_ad,''));
  if v_ad = '' then raise exception 'Ad soyad gerekli'; end if;
  if p_tip not in ('masa','gelal','magaza') then raise exception 'Geçersiz teslimat tipi'; end if;
  if p_tip = 'masa'   and btrim(coalesce(p_masa,'')) = '' then raise exception 'Masa numarası gerekli'; end if;
  if p_tip = 'magaza' and (btrim(coalesce(p_magaza,'')) = '' or btrim(coalesce(p_kat,'')) = '')
     then raise exception 'Mağaza ve kat bilgisi gerekli'; end if;
  if (select count(*) from lavka_siparis where t_yeni > now() - interval '1 minute') > 40
     then raise exception 'Sistem şu an çok yoğun, lütfen birazdan tekrar deneyin'; end if;

  select jsonb_agg(jsonb_build_object('id', m.id, 'ad', m.ad, 'fiyat', m.fiyat,
                                      'sure', m.sure, 'istasyon', m.istasyon, 'adet', k.adet)),
         coalesce(sum(m.fiyat * k.adet), 0), coalesce(max(m.sure), 0), coalesce(sum(k.adet), 0)
    into v_kalemler, v_ara, v_enuzun, v_adet
  from jsonb_to_recordset(p_kalemler) as k(id text, adet int)
  join lavka_menu m on m.id = k.id and m.satista
  where k.adet between 1 and 20;

  if v_kalemler is null then raise exception 'Sepette satışta olan ürün yok'; end if;

  select count(*) into v_kuyruk from lavka_siparis where durum not in ('teslim','iptal');
  v_soz := greatest(6, round(3 + v_enuzun + greatest(v_adet - 1, 0) * 1.2
            + least(8, v_kuyruk * 1.2)
            + case p_tip when 'masa' then 3 when 'magaza' then 8 else 0 end));
  v_servis := case when p_tip = 'magaza' then 25 else 0 end;
  v_kod := 'LV-' || nextval('lavka_kod_seq');

  return query
  insert into lavka_siparis(kod, ad, tel, tip, masa, magaza, kat, siparis_notu, odeme,
                            kalemler, ara_toplam, servis, toplam, soz_dk, gecmis)
  values (v_kod, left(v_ad,60), left(coalesce(p_tel,''),30), p_tip,
          left(coalesce(p_masa,''),20), left(coalesce(p_magaza,''),60), left(coalesce(p_kat,''),40),
          left(coalesce(p_not,''),300), coalesce(nullif(p_odeme,''),'online'),
          v_kalemler, v_ara, v_servis, v_ara + v_servis, v_soz,
          jsonb_build_array(jsonb_build_object('ts', now(), 'dur', 'yeni',
            'kim', 'Misafir · ' || left(v_ad,60), 'mesaj', 'Sipariş oluşturuldu')))
  returning lavka_siparis.kod, lavka_siparis.takip_token, lavka_siparis.soz_dk,
            lavka_siparis.toplam, lavka_siparis.t_yeni;
end $$;

-- Misafir kendi siparişini okur (kod + token).
create or replace function lavka_siparis_durum(p_kod text, p_token uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select to_jsonb(s) - 'takip_token'
  from lavka_siparis s where s.kod = p_kod and s.takip_token = p_token;
$$;

-- Misafir iptali: yalnızca hazırlığa başlanmadan önce.
create or replace function lavka_siparis_iptal(p_kod text, p_token uuid, p_sebep text default '')
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_row lavka_siparis;
begin
  select * into v_row from lavka_siparis where kod = p_kod and takip_token = p_token;
  if not found then raise exception 'Sipariş bulunamadı'; end if;
  if v_row.durum not in ('yeni','onay') then raise exception 'Hazırlığa başlanan sipariş iptal edilemez'; end if;
  update lavka_siparis set durum = 'iptal', t_iptal = now(), guncelleme = now(),
    iptal_sebep = left(coalesce(nullif(btrim(p_sebep),''),'Misafir iptal etti'),200),
    gecmis = gecmis || jsonb_build_object('ts', now(), 'dur', 'iptal', 'kim', 'Misafir',
             'mesaj', 'İptal: ' || left(coalesce(nullif(btrim(p_sebep),''),'Misafir iptal etti'),200))
    where id = v_row.id;
  return lavka_siparis_durum(p_kod, p_token);
end $$;

-- Gel-al siparişini misafir teslim aldı.
create or replace function lavka_siparis_teslim_aldim(p_kod text, p_token uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_row lavka_siparis;
begin
  select * into v_row from lavka_siparis where kod = p_kod and takip_token = p_token;
  if not found then raise exception 'Sipariş bulunamadı'; end if;
  if v_row.durum <> 'hazir' or v_row.tip <> 'gelal' then raise exception 'Bu sipariş için uygun bir işlem değil'; end if;
  update lavka_siparis set durum = 'teslim', t_teslim = now(), guncelleme = now(),
    gecmis = gecmis || jsonb_build_object('ts', now(), 'dur', 'teslim',
             'kim', 'Misafir · gel-al', 'mesaj', 'Teslim Edildi')
    where id = v_row.id;
  return lavka_siparis_durum(p_kod, p_token);
end $$;

-- Değerlendirme.
create or replace function lavka_puan_ver(p_kod text, p_token uuid, p_puan int)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if p_puan not between 1 and 5 then raise exception 'Puan 1-5 arası olmalı'; end if;
  update lavka_siparis set puan = p_puan, guncelleme = now()
    where kod = p_kod and takip_token = p_token and durum = 'teslim';
  if not found then raise exception 'Değerlendirilecek sipariş bulunamadı'; end if;
  return lavka_siparis_durum(p_kod, p_token);
end $$;

-- Tezgâh üstü hazır sipariş panosu (kişisel veri içermez).
create or replace function lavka_pano()
returns table(kod text, durum text, tip text, ad_kisa text, t_yeni timestamptz,
              t_hazir timestamptz, soz_dk int, ek_sure int)
language sql stable security definer set search_path = public as $$
  select s.kod, s.durum, s.tip, split_part(s.ad, ' ', 1), s.t_yeni, s.t_hazir, s.soz_dk, s.ek_sure
  from lavka_siparis s
  where s.durum in ('onay','hazirlik','hazir') and s.t_yeni > now() - interval '8 hours'
  order by s.t_yeni;
$$;

-- ═════════════════ PERSONEL FONKSİYONLARI ═══════════════
create or replace function lavka_durum_degis(p_id uuid, p_durum text, p_kurye text default '')
returns lavka_siparis language plpgsql security definer set search_path = public as $$
declare v_row lavka_siparis; v_kim text;
begin
  if not lavka_personel_mi() then raise exception 'Yetkiniz yok'; end if;
  if p_durum not in ('onay','hazirlik','hazir','yolda','teslim') then raise exception 'Geçersiz durum'; end if;
  v_kim := lavka_personel_adi();
  update lavka_siparis set
    durum      = p_durum,
    t_onay     = case when p_durum = 'onay'     then now() else t_onay end,
    t_hazirlik = case when p_durum = 'hazirlik' then now() else t_hazirlik end,
    t_hazir    = case when p_durum = 'hazir'    then now() else t_hazir end,
    t_yolda    = case when p_durum = 'yolda'    then now() else t_yolda end,
    t_teslim   = case when p_durum = 'teslim'   then now() else t_teslim end,
    kurye      = case when p_durum = 'yolda' and kurye = '' then left(coalesce(p_kurye, v_kim),60) else kurye end,
    guncelleme = now(),
    gecmis     = gecmis || jsonb_build_object('ts', now(), 'dur', p_durum, 'kim', v_kim,
                  'mesaj', case p_durum when 'onay' then 'Onaylandı' when 'hazirlik' then 'Hazırlanıyor'
                           when 'hazir' then 'Hazır' when 'yolda' then 'Yolda' else 'Teslim Edildi' end)
  where id = p_id and durum not in ('teslim','iptal')
  returning * into v_row;
  if not found then raise exception 'Sipariş bulunamadı ya da kapanmış'; end if;
  return v_row;
end $$;

create or replace function lavka_sure_ekle(p_id uuid, p_dk int)
returns lavka_siparis language plpgsql security definer set search_path = public as $$
declare v_row lavka_siparis;
begin
  if not lavka_personel_mi() then raise exception 'Yetkiniz yok'; end if;
  if p_dk not between 1 and 60 then raise exception 'Süre 1-60 dakika arası olmalı'; end if;
  update lavka_siparis set ek_sure = ek_sure + p_dk, guncelleme = now(),
    gecmis = gecmis || jsonb_build_object('ts', now(), 'dur', durum, 'kim', lavka_personel_adi(),
             'mesaj', 'Hazırlık süresi +' || p_dk || ' dk uzatıldı')
    where id = p_id and durum not in ('teslim','iptal')
    returning * into v_row;
  if not found then raise exception 'Sipariş bulunamadı ya da kapanmış'; end if;
  return v_row;
end $$;

create or replace function lavka_personel_iptal(p_id uuid, p_sebep text)
returns lavka_siparis language plpgsql security definer set search_path = public as $$
declare v_row lavka_siparis; v_sebep text;
begin
  if not lavka_personel_mi() then raise exception 'Yetkiniz yok'; end if;
  v_sebep := left(coalesce(nullif(btrim(p_sebep),''),'Belirtilmedi'),200);
  update lavka_siparis set durum = 'iptal', t_iptal = now(), iptal_sebep = v_sebep, guncelleme = now(),
    gecmis = gecmis || jsonb_build_object('ts', now(), 'dur', 'iptal', 'kim', lavka_personel_adi(),
             'mesaj', 'İptal: ' || v_sebep)
    where id = p_id and durum not in ('teslim','iptal')
    returning * into v_row;
  if not found then raise exception 'Sipariş bulunamadı ya da kapanmış'; end if;
  return v_row;
end $$;

-- ───────────────────── YETKİLENDİRME ────────────────────
revoke all on function lavka_siparis_olustur(jsonb,text,text,text,text,text,text,text,text) from public;
grant execute on function lavka_siparis_olustur(jsonb,text,text,text,text,text,text,text,text) to anon, authenticated;
grant execute on function lavka_siparis_durum(text,uuid)        to anon, authenticated;
grant execute on function lavka_siparis_iptal(text,uuid,text)   to anon, authenticated;
grant execute on function lavka_siparis_teslim_aldim(text,uuid) to anon, authenticated;
grant execute on function lavka_puan_ver(text,uuid,int)         to anon, authenticated;
grant execute on function lavka_pano()                          to anon, authenticated;
revoke all on function lavka_durum_degis(uuid,text,text) from public;
revoke all on function lavka_sure_ekle(uuid,int)         from public;
revoke all on function lavka_personel_iptal(uuid,text)   from public;
grant execute on function lavka_durum_degis(uuid,text,text) to authenticated;
grant execute on function lavka_sure_ekle(uuid,int)         to authenticated;
grant execute on function lavka_personel_iptal(uuid,text)   to authenticated;

-- ──────────── CANLI YAYIN (realtime) ────────────
-- Personel ekranları siparişleri anlık alır; RLS geçerlidir.
do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and tablename = 'lavka_siparis') then
    alter publication supabase_realtime add table lavka_siparis;
  end if;
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and tablename = 'lavka_menu') then
    alter publication supabase_realtime add table lavka_menu;
  end if;
end $$;
