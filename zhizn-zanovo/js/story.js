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
    [6, 'o_fall', 'Упал'], [6, 'o_memory', 'Память'], [6, 'o_dog', 'Старый пёс'],
    [0, 'ni_army', 'Повестка'], [0, 'ar_end', 'Дембель'], [0, 'ni_first', 'Без диплома'], [1, 'ab_arrive', 'Чужая страна'],
    [1, 'xr_city_love', '★ Другой город'], [1, 'xr_dream', '★ Две дороги'], [2, 'xr_dad_project', '★ Один день'], [2, 'xr_kid_year', '★ Два года'],
    [3, 'xr_friend_kid', '★ Один вечер'], [3, 'xr_truth', '★ Сказать или нет'], [3, 'xr_north', '★ Полгода']
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
  // Карта главы как в Detroit: развилки по времени, у каждой — что выбрал, что ещё можно было, и к чему это привело.
  Z.chRange = function (ch) { var a = (Z.CHAPTERS[ch].from - 18) * 12, b = Z.CHAPTERS[ch + 1] ? (Z.CHAPTERS[ch + 1].from - 18) * 12 : 1e9; return [a, b]; };
  Z.forkMap = function (s, ch) {
    var seen = Z.forksSeen(), rg = Z.chRange(ch), forks = s.forks || {};
    var mine = Object.keys(forks).filter(function (ev) { return forks[ev].m >= rg[0] && forks[ev].m < rg[1] && FORK_BY_EV[ev]; })
      .sort(function (a, b) { return forks[a].m - forks[b].m; });
    var logs = (s.log || []).filter(function (l) { return l.m >= rg[0] && l.m < rg[1]; });
    var nodes = mine.map(function (ev, i) {
      var f = forks[ev], next = i + 1 < mine.length ? forks[mine[i + 1]].m : rg[1];
      var opts = f.all && f.all.length ? f.all.slice() : [f.t];
      Object.keys(seen[ev] || {}).forEach(function (t) { if (opts.indexOf(t) < 0) opts.push(t); });
      return {
        n: FORK_BY_EV[ev].n, xr: /★/.test(FORK_BY_EV[ev].n), age: Math.floor(18 + f.m / 12), reached: true,
        opts: opts.map(function (t) { var taken = f.t === t, kn = !!(seen[ev] && seen[ev][t]) && !taken; return { t: t, taken: taken, known: kn, r: taken ? f.r : (kn ? seen[ev][t] : '') }; }),
        led: logs.filter(function (l) { return l.m >= f.m && l.m < next; }).map(function (l) { return l.t; }).slice(0, 4)
      };
    });
    var lead = logs.filter(function (l) { return !mine.length || l.m < forks[mine[0]].m; }).map(function (l) { return l.t; }).slice(0, 4);
    var missed = Z.FORKS.filter(function (f) { return f.ch === ch && !forks[f.ev]; }).map(function (f) {
      return { n: f.n, xr: /★/.test(f.n), reached: false, known: Object.keys(seen[f.ev] || {}).length };
    });
    // Сколько дорог главы открыто за все жизни
    var all = 0, open = 0;
    Z.FORKS.filter(function (f) { return f.ch === ch; }).forEach(function (f) {
      var sv = Object.keys(seen[f.ev] || {}).length, mineOpts = forks[f.ev] && forks[f.ev].all ? forks[f.ev].all.length : 0;
      var total = Math.max(sv, mineOpts, 2); all += total; open += Math.min(sv, total);
    });
    return { nodes: nodes, lead: lead, missed: missed, open: open, all: all };
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
  // Три тихих вопроса за игру — уже не герою, а тебе. Коротко, без объяснений.
  Z.PAUSES = [
    function (s) { return 'А ты в двадцать — чего хотел?'; },
    function (s) {
      var p = s.setup.parents;
      if (p === 'both') return 'Когда ты в последний раз звонил родителям просто так?';
      if (p === 'none') return 'Чей голос ты хотел бы услышать ещё раз?';
      return 'Когда ты в последний раз звонил ' + (p === 'mom' ? 'маме' : 'папе') + ' просто так?';
    },
    function (s) { return 'Что из этой жизни ты возьмёшь в свою?'; }
  ];

  // ================= НЕЗНАКОМЕЦ (выключен: Z.STRANGER_ON) =================
  Z.STRANGER_ON = false;
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
    if (!Z.STRANGER_ON || (s.opt && s.opt.stranger === false)) { /* незнакомец выключен (решение владельца после 0.5.0) */ }
    else Z.STRANGER.forEach(function (st, i) { if (!s.f['st' + i] && a >= st.a && a < st.a + 6) { s.f['st' + i] = true; t.q.push({ id: 'stranger', ctx: { N: i } }); } });
    // Перед итогом — последняя пауза и встреча с незнакомцем лицом к лицу
    var fi = -1; t.q.forEach(function (q, i) { if (q.id === 'final_now' && fi < 0) fi = i; });
    if (fi >= 0) {
      var pre = [];
      if (!s.f.pz3) { s.f.pz3 = true; pre.push({ id: 'pause', ctx: { N: 2 } }); }
      if (Z.STRANGER_ON && !s.f.st_reveal && !(s.opt && s.opt.stranger === false) && s.f.st0) { s.f.st_reveal = true; pre.push({ id: 'stranger_reveal', ctx: {} }); }
      t.q.splice.apply(t.q, [fi, 0].concat(pre));
    }
    if (head.length) t.q = head.concat(t.q);
  });

  Z.def([
    {
      id: 'ch_start', manual: true, chapter: true, title: function (s, c) { return 'Глава ' + Z.ROMAN[c.C]; },
      text: function (s, c) { var C0 = Z.CHAPTERS[c.C]; return '«' + C0.n + '»\n\n' + C0.d + ((s.setup.values || []).length ? '\n\nЧем ты хочешь, чтобы была наполнена эта глава?' : ''); },
      choices: function (s, c) {
        var list = (s.setup.values || []).map(function (k) { return { t: Z.VALUES[k].n, run: function (st) { st.intent = { k: k, ch: c.C, hits: 0 }; return ''; } }; });
        list.push({ t: list.length ? 'Просто жить' : 'Начать', run: function (st) { st.intent = null; return ''; } });
        return list;
      }
    },
    {
      id: 'ch_end', manual: true, chapter: true, map: true, title: function (s, c) { return 'Глава ' + Z.ROMAN[c.C] + ' закончилась'; },
      text: function (s, c) {
        var t = '«' + Z.CHAPTERS[c.C].n + '» позади.';
        var it = s.intent && s.intent.ch === c.C ? s.intent : null;
        if (it) t += ' Ты хотел, чтобы эта глава была про «' + Z.VALUES[it.k].n.toLowerCase() + '». ' + (it.hits >= 6 ? 'Так и вышло: ' + it.hits + ' ' + Z.plural(it.hits, 'шаг', 'шага', 'шагов') + ' в эту сторону.' : it.hits >= 2 ? 'Получилось отчасти: ' + it.hits + ' ' + Z.plural(it.hits, 'шаг', 'шага', 'шагов') + '.' : 'Жизнь повела в другую сторону.');
        return t;
      },
      choices: [{ t: 'Дальше', res: '' }]
    },
    {
      id: 'pause', manual: true, pause: true, title: '',
      ask: function () { return { ph: 'можно не отвечать', label: '', multi: true }; },
      text: function (s, c) { return Z.PAUSES[c.N](s); },
      choices: [
        { t: 'Записать', run: function (s, c, input) { var v = (input || '').trim(); if (v) { s.diary = s.diary || []; s.diary.push({ m: s.m, q: c.N, t: v }); } return ''; } },
        { t: 'Помолчать', res: '' }
      ]
    },
    {
      id: 'stranger', manual: true, off: true, title: 'Незнакомец',
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
      id: 'stranger_reveal', manual: true, off: true, title: 'Лицом к лицу',
      text: function (s) { return 'Он приходит в последний раз — садится рядом, на край кровати, как на скамейку в парке. Свет из окна падает на его лицо, и ты наконец видишь его ясно.\n\nЭто ты. Тот, прошлый. Которому было ' + s.setup.age + '. С теми же морщинами, с той же усталостью — и с теми же ошибками.\n\n«Я пришёл не исправлять, — говорит он. — Я хотел посмотреть, каким ты можешь быть. И попросить прощения — у себя самого. Я был не таким уж плохим. Просто очень уставшим».'; },
      choices: [
        C('Простить его — себя прежнего', 'joy+10 +forgave', 'Ты берёшь его руку — свою руку — и говоришь: «Я тебя прощаю». Он закрывает глаза, будто наконец выдохнул впервые за много лет. Когда ты открываешь свои, его нет. А на душе — тихо и светло.', { log: 'Простил себя прежнего.' }),
        C('Обнять его', 'joy+8 +forgave', 'Вы обнимаетесь — два человека, которые были одним. Он тёплый и настоящий. А потом — тишина, и свет из окна.', { log: 'Обнял себя прежнего.' }),
        C('Спросить: «Зачем был второй шанс?»', 'joy+4', '«Чтобы ты увидел, что мог, — говорит он. — И чтобы понял: тот, первый, тоже мог. Он просто не знал». Он уходит, не дожидаясь ответа.')
      ]
    }
  ]);
})();
