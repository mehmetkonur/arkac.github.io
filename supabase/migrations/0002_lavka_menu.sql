-- ════════════════════════════════════════════════════════════════════
-- LAVKA MENÜSÜ — lavka.html içindeki MENÜ bloğundan üretilmiştir.
-- Yeniden çalıştırılabilir: var olan ürünün adı/fiyatı/süresi güncellenir,
-- "satista" alanına dokunulmaz (tükendi işaretleri korunur).
-- ════════════════════════════════════════════════════════════════════
insert into lavka_menu (id, kategori, ad, aciklama, fiyat, sure, ikon, istasyon, satista, sira) values
  ('kh01', 'Kahveler', 'Espresso', 'Tek shot', 60, 2, '☕', 'bar', true, 10),
  ('kh02', 'Kahveler', 'Double Espresso', 'Çift shot', 75, 2, '☕', 'bar', true, 20),
  ('kh03', 'Kahveler', 'Americano', 'Sıcak / soğuk', 80, 3, '☕', 'bar', true, 30),
  ('kh04', 'Kahveler', 'Filtre Kahve', 'Günün çekirdeği, 300 ml', 75, 3, '🫖', 'bar', true, 40),
  ('kh05', 'Kahveler', 'Latte', 'Çift shot espresso + süt', 95, 4, '🥛', 'bar', true, 50),
  ('kh06', 'Kahveler', 'Cappuccino', 'Yoğun süt köpüğü', 92, 4, '☕', 'bar', true, 60),
  ('kh07', 'Kahveler', 'Flat White', 'İnce köpük, çift shot', 98, 4, '🥛', 'bar', true, 70),
  ('kh08', 'Kahveler', 'Türk Kahvesi', 'Sade / orta / şekerli', 70, 5, '🫖', 'bar', true, 80),
  ('kh09', 'Kahveler', 'Ice Latte', 'Buzlu, soğuk süt', 105, 4, '🧊', 'bar', true, 90),
  ('ic01', 'Diğer İçecekler', 'Demleme Çay', 'İnce belli bardak', 35, 2, '🍵', 'bar', true, 100),
  ('ic02', 'Diğer İçecekler', 'Bitki Çayı', 'Ihlamur / papatya / nane-limon', 60, 4, '🌿', 'bar', true, 110),
  ('ic03', 'Diğer İçecekler', 'Sıcak Çikolata', 'Bitter çikolata, marshmallow', 98, 5, '🍫', 'bar', true, 120),
  ('ic04', 'Diğer İçecekler', 'Limonata', 'Ev yapımı, naneli', 85, 3, '🍋', 'bar', true, 130),
  ('ic05', 'Diğer İçecekler', 'Portakal Suyu', 'Taze sıkım', 95, 4, '🍊', 'bar', true, 140),
  ('ic06', 'Diğer İçecekler', 'Su (50 cl)', 'Soğuk', 25, 1, '💧', 'bar', true, 150),
  ('fr01', 'Fırın & Tatlı', 'Tereyağlı Kruvasan', 'Günlük, fırından', 85, 4, '🥐', 'firin', true, 160),
  ('fr02', 'Fırın & Tatlı', 'Çikolatalı Kruvasan', 'Bitter çikolata dolgulu', 95, 4, '🥐', 'firin', true, 170),
  ('fr03', 'Fırın & Tatlı', 'Peynirli Poğaça', 'Beyaz peynirli', 45, 3, '🥯', 'firin', true, 180),
  ('fr04', 'Fırın & Tatlı', 'Zeytinli Poğaça', 'Siyah zeytinli', 45, 3, '🫒', 'firin', true, 190),
  ('fr05', 'Fırın & Tatlı', 'San Sebastian Cheesecake', 'Dilim, ev yapımı', 145, 3, '🍰', 'firin', true, 200),
  ('fr06', 'Fırın & Tatlı', 'Havuçlu Kek', 'Cevizli, tarçınlı', 110, 3, '🍥', 'firin', true, 210),
  ('fr07', 'Fırın & Tatlı', 'Brownie', 'Sıcak servis, dondurmalı', 120, 5, '🍫', 'firin', true, 220),
  ('fr08', 'Fırın & Tatlı', 'Günün Kurabiyesi', '3 adet', 55, 2, '🍪', 'firin', true, 230),
  ('sn01', 'Sandviç & Kahvaltı', 'Tavuklu Sandviç', 'Ekşi maya ekmek, közlenmiş biber', 180, 8, '🥪', 'firin', true, 240),
  ('sn02', 'Sandviç & Kahvaltı', 'Kaşarlı Tost', 'Trakya kaşarı', 135, 7, '🧀', 'firin', true, 250),
  ('sn03', 'Sandviç & Kahvaltı', 'Karışık Tost', 'Sucuk + kaşar', 165, 8, '🥪', 'firin', true, 260),
  ('sn04', 'Sandviç & Kahvaltı', 'Avokadolu Bagel', 'Poşe yumurta ile', 195, 9, '🥑', 'firin', true, 270),
  ('sn05', 'Sandviç & Kahvaltı', 'Serpme Kahvaltı Tabağı', '9 çeşit, çay dahil', 290, 14, '🍳', 'firin', true, 280),
  ('sn06', 'Sandviç & Kahvaltı', 'Menemen', 'Sucuklu / sade', 175, 12, '🍅', 'firin', true, 290),
  ('sn07', 'Sandviç & Kahvaltı', 'Omlet', 'Peynirli / sebzeli', 150, 10, '🍳', 'firin', true, 300)
on conflict (id) do update set
  kategori = excluded.kategori, ad = excluded.ad, aciklama = excluded.aciklama,
  fiyat = excluded.fiyat, sure = excluded.sure, ikon = excluded.ikon,
  istasyon = excluded.istasyon, sira = excluded.sira, guncelleme = now();
