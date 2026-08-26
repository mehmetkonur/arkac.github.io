# Arkaç AVM

GitHub Pages üzerinde çalışan, sunucu gerektirmeyen tek dosyalık web uygulamaları.

| Sayfa | Açıklama |
|-------|----------|
| [`index.html`](index.html) | **Etkinlik Merkezi** — AVM etkinlik planlama, arşiv ve analiz sistemi (TM / TR / RU / EN) |
| [`siparis.html`](siparis.html) | **Yeme-İçme Sipariş Merkezi** — Lavka, Waka Pilav ve Dürlü Döner için online sipariş, mutfak paneli, servis/kurye takibi, süre ve performans analizi |

## siparis.html — özellikler

* **Müşteri:** restoran ve menü seçimi, sepet, teslimat şekli (masaya servis / gel-al / AVM içi mağazaya kurye), online ödeme seçenekleri
* **Sipariş takibi:** canlı durum şeridi, saniye saniye geçen/kalan süre, gecikme uyarısı, adım adım süreç zaman çizelgesi, iptal ve değerlendirme
* **Restoran mutfak paneli:** kanban sipariş ekranı (Yeni → Onaylandı → Hazırlanıyor → Hazır/Teslimat), süre uzatma, sipariş reddi, günlük KPI'lar
* **Servis / kurye paneli:** teslim bekleyen ve yoldaki siparişler, kurye ataması
* **AVM yönetimi:** gösterge paneli, gecikme uyarıları, restoran performans karşılaştırması, saatlik dağılım, en çok satan ürünler, süre analizi, CSV dışa aktarım
* **Menü & stok:** ürünleri satışa açma/kapatma, hazırlık süreleri, günlük satış adetleri

Veriler tarayıcıda (localStorage) tutulur; kurulum veya sunucu gerekmez. Sol alttaki **Demo sipariş üret** düğmesi örnek veri oluşturur, **Otomatik akış** ise siparişleri gerçek bir mutfak gibi kendiliğinden ilerletir.
