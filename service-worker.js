// Pocket Full of Sunshine - Service Worker for PWA offline support
const CACHE_NAME = 'pfos-cache-v1';
const URLS_TO_CACHE = [
  './',
  './index.html',
  './style.css',
  './qrcode.min.js',
  './html5-qrcode.min.js',
  './manifest.json',
  // Add icons if present
  './icon-192.png',
  './icon-512.png'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(URLS_TO_CACHE))
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => Promise.all(
      keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key))
    ))
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request).then(response => response || fetch(event.request))
  );
});
