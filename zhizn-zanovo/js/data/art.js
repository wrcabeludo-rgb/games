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
  Z.SCENES = {"airport": "art/scenes/airport.webp", "army": "art/scenes/army.webp", "campfire": "art/scenes/campfire.webp", "cemetery": "art/scenes/cemetery.webp", "couple_walk": "art/scenes/couple_walk.webp", "dacha": "art/scenes/dacha.webp", "dorm": "art/scenes/dorm.webp", "family_table": "art/scenes/family_table.webp", "garage": "art/scenes/garage.webp", "graduation": "art/scenes/graduation.webp", "grandkid": "art/scenes/grandkid.webp", "hospital": "art/scenes/hospital.webp", "kitchen_night": "art/scenes/kitchen_night.webp", "market": "art/scenes/market.webp", "mom_phone": "art/scenes/mom_phone.webp", "moto": "art/scenes/moto.webp", "newborn": "art/scenes/newborn.webp", "newyear": "art/scenes/newyear.webp", "office": "art/scenes/office.webp", "old_dance": "art/scenes/old_dance.webp", "quarrel": "art/scenes/quarrel.webp", "rain_window": "art/scenes/rain_window.webp", "school": "art/scenes/school.webp", "sea": "art/scenes/sea.webp", "station": "art/scenes/station.webp", "teen_door": "art/scenes/teen_door.webp", "wedding": "art/scenes/wedding.webp"};
})();
