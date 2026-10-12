// ══════════════════════════════════════════════════════════════════════
// sw.js — copia local de la página de reservas (book.vylta.lat)
//
// Algunos clientes no lograban abrir la página y su intento no llegaba ni
// al servidor: la falla estaba en su red o en GitHub Pages. Con esto, quien
// ya abrió la página una vez la tiene guardada en su celular:
//
//   • Siempre se intenta primero la versión de internet (network-first),
//     así nadie se queda con una versión vieja.
//   • Si internet tarda más de 5 s o falla, se muestra la copia guardada.
//   • Solo aplica a la navegación de páginas (HTML); los datos de citas y
//     horarios siempre vienen en vivo del servidor.
//
// Para desactivarlo en todos los celulares: publicar un sw.js que solo
// haga self.registration.unregister().
// ══════════════════════════════════════════════════════════════════════
var CACHE = 'vylta-book-v1';
var NETWORK_TIMEOUT_MS = 5000;

self.addEventListener('install', function () { self.skipWaiting(); });

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.filter(function (k) { return k !== CACHE; }).map(function (k) { return caches.delete(k); }));
    }).then(function () { return self.clients.claim(); })
      .then(function () { return self.clients.matchAll({ type: 'window' }); })
      .then(function (wins) {
        // Primera visita: la pagina abierta aun no paso por aqui; se guarda
        // ya para que la siguiente visita tenga copia aunque falle la red.
        return caches.open(CACHE).then(function (cache) {
          return Promise.all(wins.map(function (w) {
            var u = new URL(w.url);
            if (u.origin !== self.location.origin) return null;
            return fetch(u.origin + u.pathname, { cache: 'no-cache' }).then(function (res) {
              if (res.ok) return cache.put(u.origin + u.pathname, res);
            }).catch(function () {});
          }));
        });
      })
  );
});

self.addEventListener('fetch', function (event) {
  var req = event.request;
  if (req.method !== 'GET' || req.mode !== 'navigate') return;
  var url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  var key = url.origin + url.pathname; // sin ?fbclid=... ni otros parametros

  event.respondWith(caches.open(CACHE).then(function (cache) {
    var network = fetch(req).then(function (res) {
      if (res.ok && res.type === 'basic') cache.put(key, res.clone());
      return res;
    });
    var timeout = new Promise(function (resolve) { setTimeout(resolve, NETWORK_TIMEOUT_MS); });

    // Lo que llegue primero: internet, o la copia guardada si internet tarda.
    return Promise.race([network, timeout.then(function () { return cache.match(key); })])
      .then(function (res) { return res || network; })
      .catch(function () {
        return cache.match(key).then(function (hit) { return hit || network; });
      });
  }));
});
