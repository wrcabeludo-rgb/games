// История: главы, незнакомец (тест), паузы-размышления, карта судьбы, альбом жизней.
(function () {
  'use strict';
  var Z = window.Z, R = Z.R, C = Z.C;
  var A = Z.age;

  // ================= ГЛАВЫ =================
  Z.CHAPTERS = [
    { from: 18, n: 'Первый курс', d: 'Тебе снова восемнадцать. Всё впереди — опять.' },
    { from: 23, n: 'Взросление', d: 'Диплом, первая работа, первые настоящие решения.' },
    { from: 30, n: 'Своё', d: 'Дом, семья, дело. То, что строишь своими руками.' },
    { from: 40, n: 'Середина пути', d: 'Половина дороги позади. Самое время спросить себя, туда ли идёшь.' },
    { from: 50, n: 'Урожай', d: 'То, что посеял, начинает расти. Хорошее — и не очень.' },
    { from: 60, n: 'Тишина', d: 'Меньше спешки, больше смысла. И новых вопросов.' },
    { from: 75, n: 'Век', d: 'Всё, что осталось, — подарок. Даже дождь.' }
  ];
  Z.chapterOf = function (age) { var i = 0; Z.CHAPTERS.forEach(function (c, k) { if (age >= c.from) i = k; }); return i; };
  Z.ROMAN = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

  // ================= КАРТА СУДЬБЫ =================
  // Развилки по главам: событие → название. Выбор записывается, непройденное видно серым.
  Z.FORKS = [
    [0, 'y_start', 'Факультет'], [0, 'y_newyear', 'Первый Новый год'], [0, 'y_summer1', 'Первое лето'], [0, 'y_hobby', 'Что ты любишь'],
    [0, 'y_smoke', 'Первая сигарета'], [0, 'p_early', 'Она беременна'], [0, 'y_doubt', 'Не та дорога?'], [0, 'y_grad', 'После диплома'],
    [1, 'p_katya_2', 'Катя и столица'], [1, 'p_lena_2', 'Лена и родной город'], [1, 'ab_homesick', 'Вернуться домой?'], [1, 'g_defense', 'Защита диссертации'],
    [1, 'p_wedding', 'Свадьба'], [1, 'l_flat', 'Своё жильё'], [1, 'fa_pasha_biz', 'Своё дело с Пашей'],
    [2, 'w_headhunt', 'Тебя переманивают'], [2, 'p_affair', 'Искушение'], [2, 'fam_wife_career', 'Её шанс'], [2, 'w_ownbiz_solo', 'Сам себе хозяин'],
    [2, 'pa_dad_regret', 'Папина мечта'], [2, 'w_burnout', 'Выгорание'],
    [3, 'l_midlife', 'Середина пути'], [3, 'pa_old', 'Родители стареют'], [3, 'l_trip', 'Мечта о путешествии'], [3, 'pa_parents_fight', 'Ссора родителей'],
    [4, 'pa_house', 'Родительский дом'], [4, 'l_meaning', 'Зачем всё это'], [4, 'fam_empty', 'Пустое гнездо'],
    [5, 'o_pension', 'Пенсия'], [5, 'o_youth_trip', 'Туда, где всё началось'], [5, 'o_letters', 'Письма детям'], [5, 'o_alone', 'Одному'],
    [6, 'o_fall', 'Упал'], [6, 'o_memory', 'Память'], [6, 'o_dog', 'Старый пёс']
  ].map(function (r) { return { ch: r[0], ev: r[1], n: r[2] }; });
  var FORK_BY_EV = {}; Z.FORKS.forEach(function (f) { FORK_BY_EV[f.ev] = f; });
  var SEEN_KEY = 'zhizn_zanovo_forks_v1';
  Z.forksSeen = function () { try { return JSON.parse(localStorage.getItem(SEEN_KEY) || '{}'); } catch (e) { return {}; } };
  Z.forksSave = function (o) { try { localStorage.setItem(SEEN_KEY, JSON.stringify(o)); } catch (e) { } };
  Z.onApply.push(function (s, e, c, ctx, inst, done) {
    var f = FORK_BY_EV[e.id]; if (!f) return;
    s.forks = s.forks || {};
    if (s.forks[e.id]) return;
    var label = Z.t(c.t, s, ctx);
    s.forks[e.id] = { t: label, r: String(done.res || '').split('\n')[0].slice(0, 160), m: s.m, all: (inst.opts || []) };
    var seen = Z.forksSeen(); seen[e.id] = seen[e.id] || {}; seen[e.id][label] = s.forks[e.id].r; Z.forksSave(seen);
  });
  Z.forkMap = function (s, ch) {
    var seen = Z.forksSeen();
    return Z.FORKS.filter(function (f) { return f.ch === ch; }).map(function (f) {
      var mine = s.forks && s.forks[f.ev];
      var opts = mine && mine.all && mine.all.length ? mine.all.slice() : [];
      Object.keys(seen[f.ev] || {}).forEach(function (t) { if (opts.indexOf(t) < 0) opts.push(t); });
      return {
        n: f.n, reached: !!mine,
        opts: opts.map(function (t) {
          var taken = mine && mine.t === t;
          return { t: t, taken: taken, known: !!(seen[f.ev] && seen[f.ev][t]), r: taken ? mine.r : (seen[f.ev] && seen[f.ev][t]) || '' };
        })
      };
    });
  };

  // ================= АЛЬБОМ ЖИЗНЕЙ =================
  var ALB_KEY = 'zhizn_zanovo_album_v1';
  Z.album = function () { try { return JSON.parse(localStorage.getItem(ALB_KEY) || '[]'); } catch (e) { return []; } };
  Z.albumAdd = function (s, E) {
    var list = Z.album();
    if (list.some(function (x) { return x.id === s.id; })) return list;
    var P = Z.P(s), cmp = Z.compass ? Z.compass(s) : null;
    list.unshift({
      id: s.id, at: Date.now(), name: s.setup.name, from: s.setup.age, age: E.age, title: E.title, old: !!E.old, death: !!E.death,
      wife: P && Z.married(s) ? P.n : (s.f.widower ? 'вдовец' : s.cnt.divorce ? 'разведён' : '—'),
      kids: Z.kids(s).map(function (k) { return k.n; }).join(', ') || '—',
      parents: Z.parentsAlive(s).length === 2 ? 'оба жили долго' : (s.risk.mom === null || s.risk.dad === null) ? 'спас' : '—',
      friends: s.close.filter(function (id) { return s.pp[id].alive; }).map(function (id) { return s.pp[id].n; }).join(', ') || '—',
      track: Z.trackStr(s) || '—', fixed: E.fixed + ' из ' + E.goals.length,
      values: (s.setup.values || []).map(function (k) { return Z.VALUES[k].n; }).join(', '), compass: cmp ? cmp.level : 0,
      forks: Object.keys(s.forks || {}).length
    });
    try { localStorage.setItem(ALB_KEY, JSON.stringify(list.slice(0, 40))); } catch (e) { }
    return list;
  };

  // ================= ПАУЗЫ (обращение к игроку) =================
  Z.PAUSES = [
    function (s) { return 'Это уже не про героя. Про тебя.\n\nВспомни себя в двадцать. Чего ты тогда хотел больше всего? Осталось ли это в тебе — хотя бы немного?'; },
    function (s) {
      var p = s.setup.parents;
      if (p === 'both') return 'Остановимся на минуту. Это вопрос не герою — тебе.\n\nТвои настоящие родители живы. Когда ты последний раз говорил с ними не по делу? Что ты хотел бы им сказать, пока можно?';
      if (p === 'none') return 'Остановимся на минуту. Это вопрос не герою — тебе.\n\nВспомни одну минуту с мамой или папой, которую ты хотел бы прожить ещё раз. Какая она? Что бы ты сказал в ней?';
      return 'Остановимся на минуту. Это вопрос не герою — тебе.\n\nУ тебя есть ' + (p === 'mom' ? 'мама' : 'папа') + '. Когда ты последний раз говорил с ' + (p === 'mom' ? 'ней' : 'ним') + ' не по делу? И что ты носишь в себе о том, кого уже нет?';
    },
    function (s) { return 'Игра почти закончилась. Последний вопрос — тебе, не герою.\n\nКакой один шаг из этой жизни ты можешь сделать в своей — на этой неделе? Маленький. Настоящий.'; }
  ];

  // ================= НЕЗНАКОМЕЦ (тест) =================
  Z.STRANGER = [
    { a: 18.15, t: 'Ночь, коридор общаги. У окна курит старик в длинном пальто — откуда он здесь? Он смотрит на тебя так, будто знает давно. «Ну что, второй раз? — говорит он тихо. — Не торопись исправлять. Сначала поживи».' },
    { a: 24.5, t: 'Вокзал, электричка опаздывает. Рядом на скамейке садится тот самый старик из общаги. Он не постарел ни на день. «Ты так боишься повторить ошибки, — говорит он, — что забываешь совершать новые. Новые — это и есть жизнь».' },
    { a: 39, t: 'Парк, осень. На скамейке — старик в длинном пальто. Ты садишься рядом, будто так и договаривались. «Знаешь, о чём я жалею больше всего? — спрашивает он. — Не об ошибках. О том, что так и не простил себе их».' },
    { a: 57, t: 'Больничный коридор, ночь. Ты ждёшь новостей, и рядом снова он — тот самый старик. «Я когда-то тоже ждал вот так, — говорит он. — И не успел. А ты — успеваешь?»' }
  ];

  Z.onTurn.push(function (s, t) {
    var a = A(s), head = [];
    // Новая глава: итог прошлой (карта судьбы) и титул новой
    var ch = Z.chapterOf(a);
    if (s.chI == null) { s.chI = ch; if (s.m === 0) head.push({ id: 'ch_start', ctx: { C: 0 } }); }
    else if (ch > s.chI) {
      for (var k = s.chI; k < ch; k++) head.push({ id: 'ch_end', ctx: { C: k } });
      if (!s.f.pz1 && a >= 23) { s.f.pz1 = true; head.push({ id: 'pause', ctx: { N: 0 } }); }
      s.chI = ch; head.push({ id: 'ch_start', ctx: { C: ch } });
    }
    // Пауза в середине пути
    var mid = Math.max(30, Math.round((23 + s.setup.age) / 2));
    if (!s.f.pz2 && s.f.pz1 && a >= mid) { s.f.pz2 = true; head.push({ id: 'pause', ctx: { N: 1 } }); }
    // Незнакомец
    if (s.opt && s.opt.stranger === false) { /* выключен в настройках */ }
    else Z.STRANGER.forEach(function (st, i) { if (!s.f['st' + i] && a >= st.a && a < st.a + 6) { s.f['st' + i] = true; t.q.push({ id: 'stranger', ctx: { N: i } }); } });
    // Перед итогом — последняя пауза и встреча с незнакомцем лицом к лицу
    var fi = -1; t.q.forEach(function (q, i) { if (q.id === 'final_now' && fi < 0) fi = i; });
    if (fi >= 0) {
      var pre = [];
      if (!s.f.pz3) { s.f.pz3 = true; pre.push({ id: 'pause', ctx: { N: 2 } }); }
      if (!s.f.st_reveal && !(s.opt && s.opt.stranger === false) && s.f.st0) { s.f.st_reveal = true; pre.push({ id: 'stranger_reveal', ctx: {} }); }
      t.q.splice.apply(t.q, [fi, 0].concat(pre));
    }
    if (head.length) t.q = head.concat(t.q);
  });

  Z.def([
    {
      id: 'ch_start', manual: true, chapter: true, title: function (s, c) { return 'Глава ' + Z.ROMAN[c.C]; },
      text: function (s, c) { var C0 = Z.CHAPTERS[c.C]; return '«' + C0.n + '»\n\n' + C0.d; },
      choices: [{ t: 'Начать', res: '' }]
    },
    {
      id: 'ch_end', manual: true, chapter: true, map: true, title: function (s, c) { return 'Глава ' + Z.ROMAN[c.C] + ' закончилась'; },
      text: function (s, c) { return '«' + Z.CHAPTERS[c.C].n + '» позади. Вот развилки этой главы: пройденные дороги светятся, непройденные — серые. Какие-то из них ты, может быть, пройдёшь в другой жизни.'; },
      choices: [{ t: 'Дальше', res: '' }]
    },
    {
      id: 'pause', manual: true, pause: true, title: 'Вопрос к тебе',
      ask: function () { return { ph: 'Можно написать пару слов — они останутся только на этом телефоне', label: '', multi: true }; },
      text: function (s, c) { return Z.PAUSES[c.N](s); },
      choices: [
        { t: 'Записать', run: function (s, c, input) { var v = (input || '').trim(); if (!v) return 'Ничего страшного. Иногда ответ — это молчание.'; s.diary = s.diary || []; s.diary.push({ m: s.m, q: c.N, t: v }); return 'Записано. В конце игры ты сможешь это перечитать.'; } },
        { t: 'Подумать молча', res: 'Ты закрываешь глаза на минуту. Этого достаточно.' },
        { t: 'Пропустить вопрос', res: 'Хорошо. Вернёмся к жизни.' }
      ]
    },
    {
      id: 'stranger', manual: true, title: 'Незнакомец',
      text: function (s, c) { return Z.STRANGER[c.N].t; },
      choices: function (s, c) {
        var a = [
          C('Спросить: «Кто вы?»', 'joy+1', 'Он улыбается: «Узнаешь в своё время». Ты моргаешь — и его уже нет.'),
          C('Просто кивнуть', 'joy+2', 'Он кивает в ответ. Когда ты оборачиваешься, рядом пусто. Но слова остаются.')
        ];
        if (c.N === 2) a.unshift(C('Признаться: «Я тоже себя не простил»', 'joy+4', '«Знаю», — говорит он мягко. И впервые улыбается так, что у тебя щемит в груди. Потом встаёт и уходит по аллее.'));
        return a;
      }
    },
    {
      id: 'stranger_reveal', manual: true, title: 'Лицом к лицу',
      text: function (s) { return 'Он приходит в последний раз — садится рядом, на край кровати, как на скамейку в парке. Свет из окна падает на его лицо, и ты наконец видишь его ясно.\n\nЭто ты. Тот, прошлый. Которому было ' + s.setup.age + '. С теми же морщинами, с той же усталостью — и с теми же ошибками.\n\n«Я пришёл не исправлять, — говорит он. — Я хотел посмотреть, каким ты можешь быть. И попросить прощения — у себя самого. Я был не таким уж плохим. Просто очень уставшим».'; },
      choices: [
        C('Простить его — себя прежнего', 'joy+10 +forgave', 'Ты берёшь его руку — свою руку — и говоришь: «Я тебя прощаю». Он закрывает глаза, будто наконец выдохнул впервые за много лет. Когда ты открываешь свои, его нет. А на душе — тихо и светло.', { log: 'Простил себя прежнего.' }),
        C('Обнять его', 'joy+8 +forgave', 'Вы обнимаетесь — два человека, которые были одним. Он тёплый и настоящий. А потом — тишина, и свет из окна.', { log: 'Обнял себя прежнего.' }),
        C('Спросить: «Зачем был второй шанс?»', 'joy+4', '«Чтобы ты увидел, что мог, — говорит он. — И чтобы понял: тот, первый, тоже мог. Он просто не знал». Он уходит, не дожидаясь ответа.')
      ]
    }
  ]);
})();
