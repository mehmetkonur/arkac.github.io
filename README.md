# Arkaç AVM

GitHub Pages üzerinde çalışan, sunucu gerektirmeyen tek dosyalık web uygulamaları.

| Sayfa | Açıklama |
|-------|----------|
| [`index.html`](index.html) | **Etkinlik Merkezi** — AVM etkinlik planlama, arşiv ve analiz sistemi (TM / TR / RU / EN) |
| [`siparis.html`](siparis.html) | **Yeme-İçme Sipariş Merkezi** — Lavka, Waka Pilav ve Dürlü Döner için online sipariş, mutfak paneli, servis/kurye takibi, süre ve performans analizi |
| [`lavka.html`](lavka.html) | **Lavka Sipariş Merkezi** — Lavka kafe & fırın için özel sürüm: online sipariş, bar/fırın ekranı, hazır sipariş panosu, gün raporu ve menü/stok yönetimi |

## siparis.html — özellikler

* **Müşteri:** restoran ve menü seçimi, sepet, teslimat şekli (masaya servis / gel-al / AVM içi mağazaya kurye), online ödeme seçenekleri
* **Sipariş takibi:** canlı durum şeridi, saniye saniye geçen/kalan süre, gecikme uyarısı, adım adım süreç zaman çizelgesi, iptal ve değerlendirme
* **Restoran mutfak paneli:** kanban sipariş ekranı (Yeni → Onaylandı → Hazırlanıyor → Hazır/Teslimat), süre uzatma, sipariş reddi, günlük KPI'lar
* **Servis / kurye paneli:** teslim bekleyen ve yoldaki siparişler, kurye ataması
* **AVM yönetimi:** gösterge paneli, gecikme uyarıları, restoran performans karşılaştırması, saatlik dağılım, en çok satan ürünler, süre analizi, CSV dışa aktarım
* **Menü & stok:** ürünleri satışa açma/kapatma, hazırlık süreleri, günlük satış adetleri

Veriler tarayıcıda (localStorage) tutulur; kurulum veya sunucu gerekmez. Sol alttaki **Demo sipariş üret** düğmesi örnek veri oluşturur, **Otomatik akış** ise siparişleri gerçek bir mutfak gibi kendiliğinden ilerletir.

## lavka.html — Lavka'ya özel sürüm

Tek işletme için sadeleştirilmiş, Lavka kimliğine göre tasarlanmış sürüm. `siparis.html`'ten farkları:

* **Ürünler istasyona ayrılır:** her ürün *bar* (içecek) veya *fırın* (yiyecek) istasyonuna bağlıdır; bar/fırın ekranı istasyona göre filtrelenir, fişlerde bar satırları renkle ayrılır
* **Hazır sipariş panosu:** tezgâh üstü ekran için büyük sipariş kodları, tam ekran desteği
* **Menü & stok yönetimi:** fiyat ve hazırlık süresi sayfa içinden düzenlenir, tükenen ürün satışa kapatılır, menü JSON olarak dışa aktarılır
* **Gün raporu:** saatlik dağılım, en çok satanlar, istasyon (bar/fırın) ciro kırılımı, süreç adımı süreleri ve hedef karşılaştırması, memnuniyet puanı, CSV dışa aktarım
* **Masa haritası ve adisyon:** salon/teras/tezgâh katları, boş-dolu-rezerve masa kartları, masa başına açık hesap tutarı ve süresi
* **Dokunmatik POS ekranı:** adisyon fişi, büyük ürün kartları, ikram, iade, iskonto, adisyon bölme/taşıma, fiş yazdırma, nakit/kart tahsilat
* **QR menü:** masadaki karekoddan açılan fotoğraflı misafir menüsü (kategori kapakları, ürün detayı, sepete ekleme)
* **Açık / koyu görünüm:** sistem temasına uyar, sol alttan da değiştirilebilir (gece vardiyasında bar ekranı için)

### Gerçek menüyü yükleme

`lavka.html` dosyasının başındaki **MENÜ** bloğu ürün adlarını, kategorileri, fiyatları, hazırlık sürelerini ve istasyonları tutar; kalıcı değişiklik için burası düzenlenir. Ürünlerin `id` değerleri korunduğu sürece geçmiş sipariş kayıtları bozulmaz. Fiyat/süre/stok değişiklikleri ayrıca **Menü & Stok** ekranından yapılabilir (tarayıcıda saklanır, JSON olarak indirilebilir).
