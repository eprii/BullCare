'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "43cfe9e113d29b34c0d6e69d3210db41",
"assets/AssetManifest.bin.json": "705f8656066da92ed8c2fdaadc903e67",
"assets/assets/branding/bull_logo_black.png": "24bce38a8a8fdefc5d9c607706fa5846",
"assets/assets/branding/kalsel_logo.png": "8437059a3d5162bf314da704007a47ec",
"assets/assets/bulls/bull_1.jpg": "9fdba4c6961b7ceb2b1034ed4d9e5783",
"assets/assets/bulls/bull_2.jpg": "2657335fbe30495ac6423d111318cad8",
"assets/assets/bulls/bull_3.jpg": "c97bb31ed3cb02212ef55538dbd95e73",
"assets/assets/bulls/bull_4.jpg": "7b72ab89a3b36d4de82b5fa73ca06c03",
"assets/assets/icon/ic_launcher.png": "0ee31e1ff26c677d4dc02fc336380bcb",
"assets/assets/icon/ic_launcher_background.png": "4ce27fb9f2de98590a39ec001ee8e54f",
"assets/assets/icon/ic_launcher_foreground.png": "d3ae798d4f7c1ce9b28b6a091129d4db",
"assets/assets/icon/ic_launcher_monochrome.png": "d34c1053553e4cfe6b856676c3cccf73",
"assets/assets/report/report_pdf_icon.png": "89fb04a0e088e615396c966b8df75256",
"assets/assets/report/report_word_icon.png": "421108f4141da68237d1d07961204633",
"assets/assets/templates/bib_kalsel_logo.png": "1c77ab6cf5d79d3ee98b8398153b21e1",
"assets/assets/templates/form_pemberian_obat_cacing_sop_6_3d.docx": "4166e6f8c3e1352f5526fe8b66d5e50d",
"assets/assets/templates/form_pemberian_obat_cacing_sop_6_3d_page_1.png": "77a2a0358b47536bbf763e36a40a6824",
"assets/assets/templates/form_pemberian_pakan_sop_6_3a.docx": "489675a7577dbc2bfb5780d6e33ef686",
"assets/assets/templates/form_pemberian_pakan_sop_6_3a_page_1.png": "9d76740ccae32258083410400b6292b4",
"assets/assets/templates/form_pemberian_pakan_sop_6_3a_page_2.png": "b2b98d5dd8d833bacfc45c03fb026229",
"assets/assets/templates/form_pemberian_pakan_sop_6_3a_page_3.png": "f65871528952a86822f778a52d983a26",
"assets/assets/templates/form_pemeriksaan_kesehatan_sop_6_3o.docx": "e2baa562c2ea2654e13fff2a86423d43",
"assets/assets/templates/form_pemeriksaan_kesehatan_sop_6_3o_page_1.png": "5d05d28a139a3f55cd348a3278ff074a",
"assets/assets/templates/form_pemotongan_bulu_sop_6_3f.docx": "23f77e142b4fe9735477cbc494ead4a9",
"assets/assets/templates/form_pemotongan_bulu_sop_6_3f_page_1.png": "898623f51f9a73a3f33e842e46a30153",
"assets/assets/templates/form_pemotongan_kuku_sop_6_3g.docx": "10bc6808f72a57d0b9ea7354d8724a1b",
"assets/assets/templates/form_pemotongan_kuku_sop_6_3g_page_1.png": "8b6f1beeb937f9727ca30c91527be608",
"assets/assets/templates/form_penampungan_semen_sop_7_5_1f.docx": "f4d9edd443d22908483ba53616493f7f",
"assets/assets/templates/form_penampungan_semen_sop_7_5_1f_page_1.png": "6831d0fbaea3b0b01dc383554d619b04",
"assets/assets/templates/form_pengobatan_pejantan_sop_6_3e.docx": "0fccb36e90a33da400a84b13a3039a55",
"assets/assets/templates/form_pengobatan_pejantan_sop_6_3e_page_1.png": "68f1c002a5303b7e407e2c442bd95194",
"assets/assets/templates/form_pengobatan_pejantan_sop_6_3e_page_2.png": "8f10028a6a0ba273334e186083f9d3ed",
"assets/assets/templates/form_pengukuran_pejantan_sop_6_3c.docx": "62cd6d0dd47f9d5f50d588f2ea9c5ba2",
"assets/assets/templates/form_pengukuran_pejantan_sop_6_3c_page_1.png": "285b1ce2ee5df0ba1c1694e50f7c1db0",
"assets/assets/templates/form_penimbangan_pejantan_sop_6_3b.docx": "6bfc8520ea71c7e9286540eed55f3b44",
"assets/assets/templates/form_penimbangan_pejantan_sop_6_3b_page_1.png": "8c885540a222ac3dc3963e9555b7024b",
"assets/assets/templates/form_sanitasi_sop_6_3_l.docx": "2859e20cc51c56cc8f8401a49d205944",
"assets/assets/templates/logo_disbunnak.jpeg": "8016868dd5aac95ad558db6f20e3b62b",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "d55a25ebe0df1e453d9ce2c53000b516",
"assets/NOTICES": "b1358b557da42c5aa2f2228223bb9d30",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "04bf2c35dede5e18c78716a00f4a17dd",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "e2d3f94fda05b0b7f39d776e8a9daa71",
"/": "e2d3f94fda05b0b7f39d776e8a9daa71",
"main.dart.js": "909c317e008e2c54a5d35d0973ba6ff3",
"manifest.json": "ad96a379f54d3a1c877b59a032776c3f",
"version.json": "4edba5d4f283deb261860731a04d9be9"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
