/* Lavka — çevrimdışı çalışma için servis çalışanı (service worker)
   Uygulama dosyaları kurulumda önbelleğe alınır; ağ yoksa önbellekten sunulur.
   Sürüm değişince eski önbellek silinir. */
var SURUM = "lavka-v1";
var DOSYALAR = [
  "./lavka.html",
  "./lavka-config.js",
  "./lib/supabase-js-2.58.0.js",
  "./manifest.json",
  "./ikon/lavka-192.png",
  "./ikon/lavka-512.png"
];

self.addEventListener("install", function (e) {
  e.waitUntil(
    caches.open(SURUM).then(function (c) {
      return Promise.all(DOSYALAR.map(function (d) {
        return c.add(d).catch(function () { /* eksik dosya kurulumu bozmasın */ });
      }));
    }).then(function () { return self.skipWaiting(); })
  );
});

self.addEventListener("activate", function (e) {
  e.waitUntil(
    caches.keys().then(function (adlar) {
      return Promise.all(adlar.filter(function (a) { return a !== SURUM; })
        .map(function (a) { return caches.delete(a); }));
    }).then(function () { return self.clients.claim(); })
  );
});

self.addEventListener("fetch", function (e) {
  var istek = e.request;
  if (istek.method !== "GET") return;
  var url = new URL(istek.url);
  if (url.origin !== self.location.origin) return;           /* Supabase ve yazı tipleri ağdan */
  if (istek.mode === "navigate") {
    e.respondWith(fetch(istek).catch(function () { return caches.match("./lavka.html"); }));
    return;
  }
  e.respondWith(
    caches.match(istek).then(function (c) {
      return c || fetch(istek).then(function (y) {
        if (y && y.status === 200 && y.type === "basic") {
          var kopya = y.clone();
          caches.open(SURUM).then(function (ch) { ch.put(istek, kopya); });
        }
        return y;
      });
    })
  );
});
