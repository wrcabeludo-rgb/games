// Сервис-воркер: сначала сеть (чтобы новые версии приходили сразу), без сети — из кэша.
const CACHE = 'zhizn-zanovo-v0.1.0';
const FILES = [
  './', 'index.html', 'manifest.webmanifest', 'css/style.css',
  'js/data/people.js', 'js/engine.js', 'js/life.js', 'js/data/ev_youth.js', 'js/data/ev_love.js',
  'js/data/ev_family.js', 'js/data/ev_friends.js', 'js/data/ev_work.js', 'js/data/ev_life.js',
  'js/endings.js', 'js/setup.js', 'js/ui.js',
  'icons/icon-192.png', 'icons/icon-512.png', 'icons/icon-maskable-512.png', 'icons/apple-touch-icon.png'
];
self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  e.respondWith(
    fetch(e.request).then(r => {
      const copy = r.clone();
      caches.open(CACHE).then(c => c.put(e.request, copy));
      return r;
    }).catch(() => caches.match(e.request, { ignoreSearch: true }))
  );
});
