// Готовые иллюстрации. Ключ — стиль возраста (Z.STYLES), внутри — тема (Z.themeOf) или stage — обложка периода.
// Добавлять сюда только файлы, которые реально лежат в art/ (иначе браузер будет искать несуществующее).
(function () {
  'use strict';
  var Z = window.Z;
  Z.ART = {
    pencils: { stage: 'art/pencils/stage.webp' },     // до 30 — цветные карандаши
    gel: { stage: 'art/gel/stage.webp' },         // до 40 — гелевые ручки
    markers: { stage: 'art/markers/stage.webp' },     // до 50 — фломастеры
    acrylic: { stage: 'art/acrylic/stage.webp' },     // до 60 — акриловые краски
    watercolor: { stage: 'art/watercolor/stage.webp' },  // до 70 — пастельная акварель
    graphite: { stage: 'art/graphite/stage.webp' },  // 70–79 — простой карандаш
    liner: { stage: 'art/liner/stage.webp' },        // 80–89 — тонкий линер, только контуры
    oneline: { stage: 'art/oneline/stage.webp' }     // 90–100 — одна непрерывная линия
  };
  // Сцены-линер из листов-раскадровок (tools/slice_sheet.py дописывает сюда сам)
  Z.SCENES = {};
})();
