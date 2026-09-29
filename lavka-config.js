/* ════════════════════════════════════════════════════════════════════
   LAVKA — BULUT YAPILANDIRMASI
   Buradaki iki değer doluysa sayfa Supabase'e bağlanır: siparişler tüm
   cihazlar arasında anlık paylaşılır. Boş bırakılırsa sayfa eskisi gibi
   tarayıcıda çalışan demo modunda açılır.

   supabaseKey herkese açık (publishable/anon) anahtardır; gizli değildir.
   Veriye erişimi Supabase tarafındaki RLS kuralları ve fonksiyonlar belirler.
   Servis (service_role) anahtarı ASLA buraya yazılmaz.
   ════════════════════════════════════════════════════════════════════ */
window.LAVKA_CONFIG = {
  supabaseUrl: "",
  supabaseKey: ""
};
