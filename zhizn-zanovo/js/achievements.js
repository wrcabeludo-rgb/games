// Достижения: копятся между жизнями (в localStorage), проверяются при подведении итога.
(function () {
  'use strict';
  var Z = window.Z;
  var KEY = 'zhizn_zanovo_ach_v1';
  Z.ACH = [
    { id: 'age100', i: '💯', n: 'Век', d: 'Дожить до ста лет — так, чтобы ни здоровье, ни кризисы не оборвали жизнь раньше.', ok: function (s) { return !!s.f.age100 || Z.age(s) >= 100; } },
    { id: 'age90', i: '🕰️', n: 'Долгожитель', d: 'Дожить до девяноста.', ok: function (s) { return Z.age(s) >= 90; } },
    { id: 'beyond', i: '🌅', n: 'Дальше прошлого', d: 'Прожить дольше, чем ты прожил в настоящей жизни, — и пойти дальше.', ok: function (s) { return Z.age(s) >= s.setup.age + 5; } },
    { id: 'parent', i: '🏡', n: 'Успел', d: 'Спасти маму или папу, которых ты потерял в прошлой жизни.', ok: function (s) { return ['mom', 'dad'].some(function (id) { return s.risk[id] === null; }); } },
    { id: 'friend', i: '🤝', n: 'Рядом в ту ночь', d: 'Спасти друга, которого ты потерял в прошлой жизни.', ok: function (s) { var r = s.risk.friend; return !!(r && s.pp[r.id].met && s.pp[r.id].alive && !s.pp[r.id].gone && (s.f.maxsaved || s.f.dimasaved || s.f.illcheck || (s.cnt.serhelp || 0) >= 2 || (s.cnt.vithelp || 0) >= 1)); } },
    { id: 'wife', i: '💍', n: 'Не отпустил', d: 'Вовремя заметить болезнь жены, которую ты потерял в прошлой жизни.', ok: function (s) { return s.setup.married === 'widow' && !!s.f.wifecheck; } },
    { id: 'golden', i: '💛', n: 'Золотая свадьба', d: 'Пятьдесят лет в браке.', ok: function (s) { return !!s.f.golden; } },
    { id: 'pastwife', i: '🔁', n: 'Та самая', d: 'Снова жениться на женщине из прошлой жизни — и не повторить ошибок.', ok: function (s) { return !!s.f.pastwife && s.partner === s.f.pastwife && Z.married(s) && s.pp[s.partner].rel >= 60 && !s.f.divorced; } },
    { id: 'allfixed', i: '✨', n: 'Всё исправил', d: 'Выполнить все цели, которые ты выбрал в начале.', ok: function (s, E) { return E && E.goals.length > 0 && E.fixed === E.goals.length; } },
    { id: 'calling', i: '🎯', n: 'Своё дело', d: 'Стать лучшим в профессии, которую любишь.', ok: function (s) { return !!s.job && s.lvl >= 3 && (s.fit[s.job] || 0) >= 30; } },
    { id: 'restart', i: '🔄', n: 'Начать с нуля', d: 'После сорока сменить область — и дорасти в новой профессии до ведущего.', ok: function (s) { return (s.career || []).some(function (c, i, all) { return i > 0 && !Z.famShare(all[i - 1].j, c.j) && (c.from / 12 + 18) >= 40 && (c.to == null ? s.lvl : c.lvl) >= 2; }); } },
    { id: 'grandpa', i: '👶', n: 'Дед', d: 'Стать дедушкой.', ok: function (s) { return !!s.f.kidwed && s.log.some(function (l) { return /дедушкой/.test(l.t); }); } },
    { id: 'great', i: '🌳', n: 'Четыре поколения', d: 'Подержать на руках правнука.', ok: function (s) { return s.log.some(function (l) { return /правнук/.test(l.t); }); } },
    { id: 'clean', i: '🌿', n: 'Чистое дыхание', d: 'Прожить жизнь без сигарет и пьянства.', ok: function (s) { return !s.f.eversmoke && !s.f.everdrink && Z.age(s) >= 40; } },
    { id: 'friends', i: '🍻', n: 'Друзья навсегда', d: 'Дойти до итога с двумя близкими друзьями.', ok: function (s) { return s.close.filter(function (id) { return s.pp[id].alive && !s.pp[id].gone && s.pp[id].rel >= 60; }).length >= 2; } },
    { id: 'stories', i: '📖', n: 'Расскажи мне', d: 'Записать истории своих родителей.', ok: function (s) { return !!s.f.stories; } }
  ];
  Z.achLoad = function () { try { return JSON.parse(localStorage.getItem(KEY) || '{}'); } catch (e) { return {}; } };
  Z.achSave = function (a) { try { localStorage.setItem(KEY, JSON.stringify(a)); } catch (e) { } };
  // Проверить жизнь: что получено в ней и что из этого — впервые
  Z.achCheck = function (s, E) {
    var got = Z.ACH.filter(function (a) { try { return a.ok(s, E); } catch (e) { return false; } });
    return got.map(function (a) { return a.id; });
  };
})();
