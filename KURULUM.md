# Lavka Sipariş Merkezi — Canlı Kurulum

`lavka.html` iki modda çalışır:

| Mod | Ne zaman | Davranış |
|-----|----------|----------|
| **Demo** | `lavka-config.js` boşken | Veriler yalnızca o tarayıcıda tutulur, siparişler otomatik ilerler. Tanıtım/deneme içindir. |
| **Canlı** | `lavka-config.js` dolduğunda | Siparişler Supabase'te tutulur; misafir telefonu, bar ekranı ve yönetim aynı veriyi anlık görür. |

---

## 1. Supabase projesi

1. [supabase.com/dashboard](https://supabase.com/dashboard) → **New project**
   * İsim: `lavka-siparis`  ·  Bölge: **eu-central-1 (Frankfurt)** (Türkiye'ye en yakın)
   * Veritabanı şifresini kaydedin (kurtarma için gerekir).
2. Proje açıldıktan sonra **Settings → General → Reference ID** değerini not edin.

### Şema ve güvenlik kurallarını yükleme

`supabase/migrations/` altındaki iki dosya sırayla çalıştırılır:

1. `0001_lavka_sema.sql` — tablolar, RLS kuralları, fonksiyonlar, canlı yayın
2. `0002_lavka_menu.sql` — menü (30 ürün; `lavka.html` içindeki MENÜ bloğundan üretilir)
3. `0003_lavka_adisyon.sql` — masalar ve adisyon (POS) tabloları (24 masa)

Supabase panelinde **SQL Editor → New query** ekranına dosyaların içeriğini yapıştırıp
çalıştırmak yeterlidir. (Aynı dosyalar tekrar çalıştırılabilir; menü güncellenir, stok
işaretleri korunur.)

### Ekip hesapları

1. **Authentication → Users → Add user** ile personel için e-posta + şifre oluşturun
   (*Auto Confirm User* işaretli olsun).
2. Ardından SQL Editor'de kullanıcıyı ekip listesine ekleyin:

```sql
insert into lavka_personel (user_id, ad, rol)
select id, 'Barista Ayşe', 'ekip' from auth.users where email = 'barista@ornek.com'
on conflict (user_id) do update set ad = excluded.ad, rol = excluded.rol, aktif = true;
```

* `rol`: `ekip` (bar/servis) veya `yonetim`. Listede olmayan hesap ekip ekranlarını açamaz.
* Ayrılan personel için: `update lavka_personel set aktif = false where ad = '…';`

## 2. Sayfayı bağlama

`lavka-config.js` dosyasını doldurun:

```js
window.LAVKA_CONFIG = {
  supabaseUrl: "https://<reference-id>.supabase.co",
  supabaseKey: "<Settings → API Keys → anon / publishable>"
};
```

`anon` anahtarı **herkese açıktır**, gizli değildir; tarayıcıya gönderilmesi normaldir.
Veriye erişimi RLS kuralları belirler. `service_role` anahtarı **asla** bu dosyaya yazılmaz.

## 3. Netlify yayını

Site hazır: **lavka-siparis.netlify.app** (Netlify panelinde `lavka-siparis`).

GitHub'a bağlayıp her push'ta otomatik yayın için:

1. [app.netlify.com/projects/lavka-siparis](https://app.netlify.com/projects/lavka-siparis)
2. **Site configuration → Build & deploy → Continuous deployment → Link repository**
3. GitHub → `mehmetkonur/arkac.github.io` deposunu seçin
4. Ayarlar: **Branch** `main` · **Build command** boş · **Publish directory** `.`
5. **Deploy site**

`netlify.toml` zaten depoda: kök adres Lavka sayfasını açar, `/avm` etkinlik merkezine,
`/foodcourt` üç restoranlı demoya gider.

## 4. Kurulum sonrası kontrol listesi

- [ ] Sayfanın sol alt köşesinde **"Canlı · misafir"** yazıyor (demo modu değil)
- [ ] Menü, veritabanındaki ürünleri gösteriyor
- [ ] Telefondan sipariş verildiğinde bar ekranında **anında** görünüyor
- [ ] Bar ekranında durum değiştirince misafir takip ekranı kendiliğinden güncelleniyor
- [ ] Hazır Panosu tezgâh ekranında kodları gösteriyor
- [ ] Çıkış yapıldığında ekip ekranları giriş istiyor

## Masa / POS hakkında

Masa haritası, adisyon (POS) ve QR menü ekranları **şu an yerel modda çalışır**: adisyonlar
tarayıcıda tutulur, mutfağa gönderilen kalemler normal sipariş kaydına dönüşür. Bulut modunda
bu ekranların çalışması için `0003_lavka_adisyon.sql` yüklenmeli ve sayfa tarafındaki adisyon
işlemleri Supabase'e bağlanmalıdır (proje açıldıktan sonra yapılacak son adım).

Masa düzenini değiştirmek için `lavka.html` başındaki **KATLAR** bloğunu düzenleyin; aynı
tanımdan `0003_lavka_adisyon.sql` içindeki masa listesi üretilir.

## Güvenlik notları

* Misafir tarayıcısı tablolara doğrudan erişemez; yalnızca sunucu fonksiyonlarını çağırır.
* Sipariş tutarı ve hazırlık süresi istemciden alınmaz, menüden sunucuda hesaplanır.
* Misafir kendi siparişini yalnızca `kod + takip_token` ikilisiyle görebilir; token cihazda saklanır.
* Durum değişiklikleri kim yaptıysa adıyla birlikte `gecmis` alanına yazılır.
* Dakikada 40'tan fazla sipariş girişimi reddedilir (kötüye kullanım koruması).
