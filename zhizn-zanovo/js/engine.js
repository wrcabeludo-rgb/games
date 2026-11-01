// Движок «Жизни заново»: состояние, месяцы, выбор событий, эффекты, шаблоны текста.
(function () {
  'use strict';
  var Z = window.Z = window.Z || {};
  Z.VERSION = '0.7.0';
  Z.EV = {};
  Z.evList = [];
  // Крючки: после выбора (s, e, choice, ctx, inst, done) и после сборки хода (s, turn)
  Z.onApply = [];
  Z.onTurn = [];

  // Регистрация событий. once — по умолчанию одноразовое; rep: N — повторяется не чаще раза в N месяцев.
  Z.def = function (list) {
    list.forEach(function (e) {
      if (Z.EV[e.id]) throw new Error('Повтор события ' + e.id);
      if (e.once === undefined) e.once = !e.rep && !e.manual;
      // События про нынешнюю жену/девушку: если она сменилась в этом же ходу — карточку пропускаем
      if (e.ctx && /P: s\.partner|curP/.test(String(e.ctx))) e.samep = true;
      Z.EV[e.id] = e;
      Z.evList.push(e);
    });
  };

  var R = Z.R = {
    rnd: Math.random,
    int: function (a, b) { return a + Math.floor(R.rnd() * (b - a + 1)); },
    chance: function (p) { return R.rnd() < p; },
    pick: function (arr) { return arr[Math.floor(R.rnd() * arr.length)]; },
    shuffle: function (arr) { arr = arr.slice(); for (var i = arr.length - 1; i > 0; i--) { var j = Math.floor(R.rnd() * (i + 1)); var t = arr[i]; arr[i] = arr[j]; arr[j] = t; } return arr; }
  };
  Z.C = function (t, fx, res, extra) { var c = { t: t, fx: fx, res: res }; if (extra) Object.keys(extra).forEach(function (k) { c[k] = extra[k]; }); return c; };
  var clamp = Z.clamp = function (v, a, b) { return Math.max(a, Math.min(b, v)); };

  Z.MONTHS = ['январь', 'февраль', 'март', 'апрель', 'май', 'июнь', 'июль', 'август', 'сентябрь', 'октябрь', 'ноябрь', 'декабрь'];
  Z.age = function (s) { return 18 + s.m / 12; };
  Z.ageInt = function (s) { return Math.floor(Z.age(s) + 1e-9); };
  Z.cal = function (s, m) { m = m == null ? s.m : m; var i = 8 + m; return { mon: i % 12, year: s.y0 + Math.floor(i / 12) }; };
  Z.dateStr = function (s, m) { var c = Z.cal(s, m); return Z.MONTHS[c.mon] + ' ' + c.year; };
  Z.plural = function (n, one, few, many) {
    var a = Math.abs(n) % 100, b = a % 10;
    if (a > 10 && a < 20) return many;
    if (b > 1 && b < 5) return few;
    if (b === 1) return one;
    return many;
  };
  Z.yearsStr = function (n) { return n + ' ' + Z.plural(n, 'год', 'года', 'лет'); };

  // ---------- Иллюстрации: стиль по возрасту ----------
  Z.STYLES = [
    { max: 30, id: 'pencils', n: 'цветные карандаши' },
    { max: 40, id: 'gel', n: 'гелевые ручки' },
    { max: 50, id: 'markers', n: 'фломастеры' },
    { max: 60, id: 'acrylic', n: 'акриловые краски' },
    { max: 70, id: 'watercolor', n: 'пастельная акварель' },
    { max: 80, id: 'graphite', n: 'простой карандаш' },
    { max: 90, id: 'liner', n: 'тонкий линер, только контуры' },
    { max: 101, id: 'oneline', n: 'одна непрерывная линия' }
  ];
  Z.styleFor = function (s) { var a = Z.age(s); for (var i = 0; i < Z.STYLES.length; i++) if (a < Z.STYLES[i].max) return Z.STYLES[i]; return Z.STYLES[Z.STYLES.length - 1]; };
  // Тема картинки по событию: родители, друзья, любовь, семья, работа, юность, серый период, старость, жизнь
  Z.themeOf = function (id) {
    var e = Z.EV[id]; if (e && e.img) return e.img;
    if (/^l_gray|^f_gray/.test(id)) return 'gray';
    if (/^pa_/.test(id)) return 'parents';
    if (/^(f_|fr_|fa_|c_)/.test(id)) return 'friends';
    if (/^p_/.test(id)) return 'love';
    if (/^(k_|fam_)/.test(id)) return 'family';
    if (/^w_/.test(id)) return 'work';
    if (/^y_/.test(id)) return 'youth';
    if (/^o_/.test(id)) return 'old';
    return 'life';
  };
  // Путь к картинке: сначала картинка темы в стиле возраста, иначе обложка периода. Z.ART — список готовых файлов (js/data/art.js).
  // Сцены-линер (листы-раскадровки): событие → ключ сцены. Сцена — в любом возрасте, приоритетнее обложки.
  Z.SCENE_RULES = [
    [/^(pa_call|pa_mom_bday|l_gray_mom|pa_tech|pa_single_worry)$/, 'mom_phone'], [/^(pa_visit|pa_dacha|pa_recipe|pa_house|pa_story|pa_letters|pa_money)$/, 'dacha'],
    [/^(pa_garage|pa_dad_regret|pa_retire|pa_dad_bday|pa_dad_smoke\d?|y_dad_smoke1|xr_dad_after)$/, 'garage'],
    [/^(pa_dad_heart|pa_mom_ill|pa_hospital|o_hospital|l_heart|fa_ill2|p_wife_ill|l_hp_crisis|pa_dad_check|pa_mom_sign|l_checkup|xr_dad_project)$/, 'hospital'],
    [/^(k_birth|k_night|k_word|p_early_born|ed_exams)$/, 'newborn'], [/^(k_school|k_play|k_bully|k_dad_job|k_sick|k_hobby)$/, 'school'],
    [/^(k_teen|k_secret|k_dark|k_tattoo|k_gap|k_career)$/, 'teen_door'], [/^(fam_dinner|fam_inlaws|pa_anniv|fam_wife_bday|fam_siblings|fam_empty|l_b\d+)$/, 'family_table'],
    [/^(k_grand|o_teach|o_great_grand|k_grandweek|pa_grandkid|pa_grandkids_summer)$/, 'grandkid'],
    [/^(y_party_katya|y_band|y_birthday|f_reunion|fr_photo|ni_students)$/, 'dorm'], [/^(f_crisis|f_gray|fr_secret|f_help|fa_depr1|fa_depr2|fa_drink2|fr_lyokha_envy|xr_friend_kid|xr_truth)$/, 'kitchen_night'],
    [/^(fa_crash1|fa_crash2|fr_max_road|y_max)$/, 'moto'], [/^(p_ask_out|p_first_date|p_romance|p_late|p_anya_1|p_lena_1|p_propose)$/, 'couple_walk'],
    [/^(p_wedding|f_wedding|k_wedding|o_golden|fr_stag)$/, 'wedding'], [/^(p_quarrel|p_crisis|p_divorce|p_breakup|p_affair_found|p_routine)$/, 'quarrel'],
    [/^(p_lena_2|p_katya_2|k_leave|ar_start|ar_end|xr_city_love|xr_city_after|fr_abroad)$/, 'station'],
    [/^(w_overtime|w_promo|w_boss|w_dilemma|w_headhunt|w_burnout|w_first_day|w_offer|w_daily|w_mentor|w_synergy|w_old_call|w_switch_doubt)$/, 'office'],
    [/^(l_gray_\w+|p_lonely|o_alone|w_unemployed)$/, 'rain_window'],
    [/^(ar_hard|ar_letter|ar_skill|ni_army)$/, 'army'], [/^(ni_first|ni_first_pay|ni_master)$/, 'market'], [/^(l_newyear|y_newyear|ni_newyear)$/, 'newyear'],
    [/^(ab_arrive|ab_parents|ab_homesick|ab_friend)$/, 'airport'], [/^(y_hike|y_sea2|y_summer1)$/, 'campfire'], [/^(y_grad|g_defense|ni_late_done)$/, 'graduation'],
    [/^(o_parent_passing|o_friend_passing|o_wife_passing|pa_after)$/, 'cemetery'], [/^(p_anniv|fam_empty)$/, 'old_dance'], [/^(l_vacation|pa_trip)$/, 'sea']
  ];
  Z.sceneOf = function (id) { for (var i = 0; i < Z.SCENE_RULES.length; i++) if (Z.SCENE_RULES[i][0].test(id)) return Z.SCENE_RULES[i][1]; return null; };
  Z.artFor = function (s, id) {
    var sc = Z.sceneOf(id);
    if (sc && Z.SCENES && Z.SCENES[sc]) return Z.SCENES[sc];
    var st = Z.styleFor(s).id, A = (Z.ART || {})[st] || {}, a = Z.age(s);
    var stage = A.stage;
    if (A[Z.themeOf(id)]) return A[Z.themeOf(id)];
    // Обложка десятилетия — только на ключевых карточках, чтобы не повторяться
    return /^(ch_start|y_start|final_now|l_b\d+)$/.test(id) ? stage || null : null;
  };

  // ---------- Склонение имён (эвристика для русских имён) ----------
  Z.decl = function (name, fem) {
    var n = String(name || '').trim() || '?';
    var low = n.toLowerCase(), last = low.slice(-1), pre = low.slice(-2, -1), st = n.slice(0, -1);
    var f = { n: n, g: n, d: n, a: n, i: n, p: n };
    var hush = 'гкхжчшщ'.indexOf(pre) >= 0, sib = 'жчшщц'.indexOf(pre) >= 0;
    if (/ия$/.test(low)) { f.g = st + 'и'; f.d = st + 'и'; f.a = st + 'ю'; f.i = st + 'ей'; f.p = st + 'и'; }
    else if (last === 'а') { f.g = st + (hush ? 'и' : 'ы'); f.d = st + 'е'; f.a = st + 'у'; f.i = st + (sib ? 'ей' : 'ой'); f.p = st + 'е'; }
    else if (last === 'я') { f.g = st + 'и'; f.d = st + 'е'; f.a = st + 'ю'; f.i = st + (pre === 'ь' ? 'ёй' : 'ей'); f.p = st + 'е'; }
    else if (fem && last === 'ь') { f.g = st + 'и'; f.d = st + 'и'; f.i = n + 'ю'; f.p = st + 'и'; }
    else if (!fem) {
      if (last === 'й' || last === 'ь') { f.g = st + 'я'; f.d = st + 'ю'; f.a = st + 'я'; f.i = st + 'ем'; f.p = st + 'е'; }
      else if (/[бвгджзклмнпрстфхцчшщ]/.test(last)) { f.g = n + 'а'; f.d = n + 'у'; f.a = n + 'а'; f.i = n + ('жчшщц'.indexOf(last) >= 0 ? 'ем' : 'ом'); f.p = n + 'е'; }
    }
    return f;
  };

  // Пол по имени: true — женское, false — мужское, null — непонятно (Саша, Женя…)
  Z.WIFE_NAMES = ['Наташа', 'Света', 'Юля', 'Таня', 'Вика', 'Настя', 'Люда', 'Галя', 'Вера', 'Полина'];
  Z.AMBIG = ['саша', 'женя', 'валя', 'слава', 'шура', 'сева'];
  Z.MALE_A = ['миша', 'никита', 'илья', 'ваня', 'даня', 'дима', 'лёша', 'леша', 'алёша', 'алеша', 'паша', 'петя', 'серёжа', 'сережа', 'костя', 'вова', 'гоша',
    'лёва', 'лева', 'федя', 'яша', 'тёма', 'тема', 'гриша', 'боря', 'митя', 'коля', 'толя', 'юра', 'кузьма', 'фома', 'лука', 'савва', 'сеня', 'стёпа', 'степа',
    'добрыня', 'ярик', 'вася', 'гена', 'рома', 'вадя', 'стас', 'лёня', 'леня', 'кеша', 'тимоша', 'данила', 'гаврила', 'никола', 'жора', 'эдя', 'артёмка'];
  Z.FEM_SOFT = ['любовь', 'нинель', 'адель', 'ассоль', 'изабель', 'эсфирь', 'юдифь'];
  Z.guessFem = function (name) {
    var n = String(name || '').trim().toLowerCase().split(/\s+/)[0];
    if (!n) return null;
    if (Z.AMBIG.indexOf(n) >= 0) return null;
    if (Z.MALE_A.indexOf(n) >= 0) return false;
    if (Z.FEM_SOFT.indexOf(n) >= 0) return true;
    if (/[ая]$/.test(n)) return true;
    return false;
  };

  // ---------- Люди ----------
  Z.person = function (s, id) { return s.pp[id]; };
  Z.addPerson = function (s, id, o) {
    var p = { id: id, n: o.n, fem: !!o.fem, kind: o.kind, rel: o.rel || 0, met: !!o.met, alive: true };
    p.forms = Z.decl(p.n, p.fem);
    s.pp[id] = p;
    return p;
  };
  Z.rename = function (s, id, name, fem) {
    var p = s.pp[id]; if (!p || !name) return;
    p.n = name.trim(); if (fem != null) p.fem = fem; p.forms = Z.decl(p.n, p.fem);
  };
  Z.meet = function (s, id, rel) { var p = s.pp[id]; if (!p) return; if (!p.met) { p.met = true; p.metM = s.m; } if (rel) p.rel = clamp(p.rel + rel, 0, 100); };
  Z.rel = function (s, id) { var p = s.pp[id]; return p && p.met && p.alive ? p.rel : 0; };
  Z.alive = function (s, id) { var p = s.pp[id]; return !!(p && p.alive); };
  Z.friendIds = function (s) { return Object.keys(Z.FRIENDS).filter(function (id) { var p = s.pp[id]; return p.met && p.alive && !p.gone; }); };
  Z.isClose = function (s, id) { return s.close.indexOf(id) >= 0; };
  Z.P = function (s) { return s.partner ? s.pp[s.partner] : null; };
  Z.married = function (s) { return !!s.partner && s.pst === 'married'; };
  Z.dating = function (s) { return !!s.partner && s.pst === 'dating'; };
  Z.single = function (s) { return !s.partner; };
  Z.kids = function (s) { return s.kids.map(function (id) { return s.pp[id]; }).filter(function (k) { return k.alive; }); };
  Z.kidAge = function (s, k) { return (s.m - k.born) / 12; };
  Z.parentsAlive = function (s) { return ['mom', 'dad'].filter(function (id) { return s.pp[id].alive; }); };
  Z.jobName = function (s) { return s.job ? Z.JOBS[s.job].n : ''; };
  Z.jobTitle = function (s) { return s.job ? (s.jobAlt || Z.JOBS[s.job].t[s.lvl]) : ''; };
  Z.working = function (s) { return !!s.job && !s.student; };
  Z.gray = function (s) { return s.st.joy < 30; };

  // ---------- Новая жизнь ----------
  Z.RISK_AGE = { a: 22, b: 30, c: 40, d: 48 };
  Z.newLife = function (setup) {
    var now = new Date().getFullYear();
    var s = {
      v: 1, ver: Z.VERSION, setup: setup, y0: now - setup.age + 18, m: 0, target: setup.age, endAge: setup.age,
      st: { hp: 85, joy: 62, money: 15, sk: 15 },
      pp: {}, f: {}, seen: {}, queue: [], log: [], kids: [], close: [], exes: [], cnt: {},
      focus: ['work', 'friends'], tempo: setup.tempo || 'normal',
      edu: null, student: true, degree: false, job: null, lvl: 0, jobM: 0, lvlM: 0, jobsHad: [],
      partner: null, pst: null, pSince: 0, wedM: null, fit: {}, grief: 0, risk: {}, started: false, over: null, turn: null
    };
    Z.addPerson(s, 'mom', { n: 'мама', fem: true, kind: 'parent', rel: 70, met: true });
    Z.addPerson(s, 'dad', { n: 'папа', kind: 'parent', rel: 60, met: true });
    Object.keys(Z.FRIENDS).forEach(function (id) { var d = Z.FRIENDS[id]; Z.addPerson(s, id, { n: d.n, fem: d.fem, kind: 'friend', rel: 0 }); });
    Object.keys(Z.PARTNERS).forEach(function (id) { Z.addPerson(s, id, { n: Z.PARTNERS[id].n, fem: true, kind: 'partner', rel: 0 }); });
    // Прошлое: потерянные родители, друг, жена.
    if (setup.parents === 'mom' || setup.parents === 'none') s.risk.dad = Z.RISK_AGE[setup.dadAge || 'b'];
    if (setup.parents === 'dad' || setup.parents === 'none') s.risk.mom = Z.RISK_AGE[setup.momAge || 'c'];
    if (setup.lostFriend && !setup.lostName) setup.lostName = R.pick(setup.lostFem ? ['Света', 'Оля', 'Таня', 'Наташа'] : ['Вова', 'Коля', 'Женя', 'Сашка', 'Игорь']);
    if (setup.married && setup.married !== 'never' && (!setup.wifeName || setup.wifeName === 'Имя')) setup.wifeName = R.pick(Z.WIFE_NAMES);
    if (setup.lostName === 'Имя') setup.lostName = R.pick(setup.lostFem ? ['Света', 'Оля'] : ['Вова', 'Коля']);
    if (setup.lostFriend) {
      var map = { crash: 'max', ill: 'zhenya', drink: 'serega', depr: 'dima', lost: 'vitya' };
      var fid = setup.lostFem && setup.lostCause === 'ill' ? 'ira' : map[setup.lostCause] || 'zhenya';
      Z.rename(s, fid, setup.lostName || s.pp[fid].n, setup.lostFem ? true : (fid === 'ira' ? true : false));
      var la = { crash: 26, ill: 38, drink: 36, depr: 31, lost: 30 }[setup.lostCause] || 33;
      s.risk.friend = { id: fid, age: la, cause: setup.lostCause };
    }
    if (setup.married && setup.married !== 'never' && setup.wifeType) {
      var wid = setup.wifeType;
      if (setup.wifeName) Z.rename(s, wid, setup.wifeName, true);
      s.f.pastwife = wid;
      if (setup.married === 'widow') s.risk.wife = { id: wid, age: Z.RISK_AGE[setup.wifeAge || 'c'] };
    }
    if (setup.job && Z.JOBS[setup.job] && !setup.regrets.calling) s.fit[setup.job] = 15;
    // Сколько лет будет родителям, когда они уйдут своей смертью (если игра пойдёт так далеко), и разница в возрасте с тобой
    s.pgap = { mom: 25 + R.int(0, 4), dad: 27 + R.int(0, 4) };
    s.pdeath = { mom: R.int(85, 97), dad: R.int(82, 94) };
    s.wifeEnd = R.int(80, 97);
    s.id = Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36);
    s.opt = { stranger: false, sound: true };
    s.queue.push({ id: 'y_start', at: 0 });
    return s;
  };

  // ---------- Шаблоны текста ----------
  // {hero}, {hero.d} — герой; {P}, {P.a} — текущая девушка/жена; {F} {K} — друг/ребёнок события;
  // {mom.d}, {anya.i} — любой человек по id; {F~пришёл|пришла} — по полу; {job}, {jobt}, {age}, {year}, {pastjob}.
  Z.who = function (s, ctx, key) {
    if (key === 'hero') return { forms: Z.decl(s.setup.name, false), fem: false };
    if (key === 'P') return s.pp[(ctx && ctx.P) || s.partner];
    if (ctx && ctx[key] && s.pp[ctx[key]]) return s.pp[ctx[key]];
    if (key === 'C1' || key === 'C2') return s.pp[s.close[key === 'C1' ? 0 : 1]];
    if (key === 'W') return s.pp[s.f.pastwife];
    return s.pp[key];
  };
  Z.t = function (str, s, ctx) {
    if (str == null) return '';
    if (typeof str === 'function') str = str(s, ctx || {});
    return String(str).replace(/\{([^{}]+)\}/g, function (all, key) {
      var m = key.match(/^(\w+)~([^|]*)\|(.*)$/);
      if (m) { var w = Z.who(s, ctx, m[1]); return w && w.fem ? m[3] : m[2]; }
      var parts = key.split('.');
      switch (parts[0]) {
        case 'job': return Z.jobName(s);
        case 'jobt': return Z.jobTitle(s);
        case 'age': return String(Z.ageInt(s));
        case 'year': return String(Z.cal(s).year);
        case 'pastjob': return s.setup.job && Z.JOBS[s.setup.job] ? Z.JOBS[s.setup.job].n : 'тем, кем ты был';
        case 'pastjobi': return s.setup.job && Z.JOB_I[s.setup.job] ? Z.JOB_I[s.setup.job] : 'тем, кем был';
        case 'jobi': return s.job ? Z.JOB_I[s.job] : '';
        case 'prevjob': var pj = Z.prevJob(s); return pj ? Z.JOBS[pj].n : '';
        case 'prevjobi': var pj2 = Z.prevJob(s); return pj2 ? Z.JOB_I[pj2] : '';
        case 'pastage': return String(s.setup.age);
        case 'edu': return s.edu ? Z.EDU[s.edu].n.toLowerCase() : '';
      }
      var p = Z.who(s, ctx, parts[0]);
      if (!p && parts[0] === 'P') { if (Z.STRICT) return '{P — нет жены}'; p = { n: 'жена', fem: true, forms: Z.decl('жена', true) }; }
      if (!p) return all;
      var f = p.forms || Z.decl(p.n, p.fem);
      return f[parts[1] || 'n'] || f.n;
    });
  };
  Z.cap = function (str) { return str ? str.charAt(0).toUpperCase() + str.slice(1) : str; };

  // ---------- Эффекты (мини-язык) ----------
  // hp+5 joy-3 money+10 sk+2 | @mom+5 @P-3 @F+4 @K+5 @kids+3 @friends+2 | +flag -flag cnt++ | >event@6 >event@3-9 | fit.prog+5 | met:serega
  Z.relId = function (s, ctx, key) {
    if (key === 'P') return (ctx && ctx.P) || s.partner;
    if (ctx && ctx[key]) return ctx[key];
    return key;
  };
  Z.addRel = function (s, id, d) { var p = s.pp[id]; if (!p || !p.alive) return; if (!p.met) Z.meet(s, id); p.rel = clamp(p.rel + d, 0, 100); };
  Z.fx = function (s, str, ctx) {
    if (!str) return;
    str.trim().split(/\s+/).forEach(function (tok) {
      var m;
      if ((m = tok.match(/^(hp|joy|money|sk)([+-]\d+)$/))) { s.st[m[1]] = clamp(s.st[m[1]] + Number(m[2]), 0, 100); return; }
      if ((m = tok.match(/^@(\w+)([+-]\d+)$/))) {
        var d = Number(m[2]), k = m[1];
        if (k === 'kids') Z.kids(s).forEach(function (p) { Z.addRel(s, p.id, d); });
        else if (k === 'friends') Z.friendIds(s).forEach(function (id) { Z.addRel(s, id, d); });
        else if (k === 'parents') Z.parentsAlive(s).forEach(function (id) { Z.addRel(s, id, d); });
        else if (k === 'close') s.close.forEach(function (id) { Z.addRel(s, id, d); });
        else { var id = Z.relId(s, ctx, k); if (id) Z.addRel(s, id, d); }
        return;
      }
      if ((m = tok.match(/^fit\.(\w+)([+-]\d+)$/))) { s.fit[m[1]] = clamp((s.fit[m[1]] || 0) + Number(m[2]), 0, 100); return; }
      if ((m = tok.match(/^hobby\.(\w+)([+-]\d+)$/))) { (Z.HOBBY[m[1]].jobs).forEach(function (j) { s.fit[j] = clamp((s.fit[j] || 0) + Number(m[2]), 0, 100); }); s.f['h_' + m[1]] = true; return; }
      if ((m = tok.match(/^mem:(\w+)(?::(\w+))?$/))) { Z.remember(s, m[1], m[2] || null, ctx); return; }
      if ((m = tok.match(/^met:(\w+)$/))) { Z.meet(s, Z.relId(s, ctx, m[1]), 15); return; }
      if ((m = tok.match(/^>(\w+)(?:@(\d+)(?:-(\d+))?)?$/))) {
        var a = m[2] ? Number(m[2]) : 1, b = m[3] ? Number(m[3]) : a;
        Z.schedule(s, m[1], R.int(a, b), ctx); return;
      }
      if ((m = tok.match(/^(\w+)\+\+$/))) { s.cnt[m[1]] = (s.cnt[m[1]] || 0) + 1; return; }
      if ((m = tok.match(/^\+(\w+)$/))) { s.f[m[1]] = true; return; }
      if ((m = tok.match(/^-(\w+)$/))) { delete s.f[m[1]]; return; }
      if (window.console) console.warn('Непонятный эффект: ' + tok);
    });
  };
  Z.schedule = function (s, id, inMonths, ctx) {
    if (!Z.EV[id]) { console.warn('Нет события ' + id); return; }
    s.queue.push({ id: id, at: s.m + Math.max(0, inMonths), ctx: ctx ? JSON.parse(JSON.stringify(ctx)) : undefined });
  };
  Z.logLine = function (s, text, kind) { s.log.push({ m: s.m, t: text, k: kind || '' }); };

  // ---------- Доход и счастье ----------
  Z.income = function (s) {
    var v;
    if (s.student) v = 12 + (Z.alive(s, 'mom') || Z.alive(s, 'dad') ? 6 : 0) + (s.f.parttime ? 8 : 0);
    else if (s.job) v = Z.JOBS[s.job].pay[s.lvl];
    else v = 8;
    if (Z.married(s) && !s.f.p_home) v += 14;
    Z.kids(s).forEach(function (k) { if (Z.kidAge(s, k) < 22) v -= 6; });
    if (s.f.mortgage) v -= 8;
    if (s.f.debt) v -= 12;
    if (s.f.savings) v += 4;
    if (s.f.abroad && s.job) v += 10;
    return clamp(v, 2, 100);
  };
  Z.joyBase = function (s) {
    var a = Z.age(s), b = 14;
    var P = Z.P(s);
    if (P) b += (P.rel - 50) * 0.3;
    else if (a > 27 && !s.f.content_alone) b -= 6;
    var fr = Z.friendIds(s).map(function (id) { return s.pp[id].rel; }).sort(function (x, y) { return y - x; });
    b += (((fr[0] || 0) + (fr[1] || 0)) / 2 - 40) * 0.15;
    Z.parentsAlive(s).forEach(function (id) { b += (s.pp[id].rel - 50) * 0.04; });
    Z.kids(s).forEach(function (k) { b += 2 + (k.rel - 50) * 0.06; });
    if (s.job && !s.student) {
      var J = Z.JOBS[s.job]; b += Math.min(40, s.fit[s.job] || 0) * 0.3 - J.stress * 0.5 + s.lvl;
    } else if (!s.student && a > 23 && !s.f.retired && !s.f.inarmy) b -= 10;
    b += (s.st.hp - 60) * 0.15 + (s.st.money - 35) * 0.12;
    if (s.f.hobby) b += 4;
    if (s.focus.indexOf('self') >= 0) b += 3;
    if (s.f.dog) b += 3;
    if (s.f.drinks) b -= 4;
    if (s.f.debt) b -= 4;
    if (s.grief > 0) b -= 14 * s.grief / 12;
    return clamp(b, 5, 95);
  };

  // ---------- Месяц жизни ----------
  Z.tick = function (s) {
    s.m++;
    var a = Z.age(s), st = s.st, f = s.f;
    var has = function (k) { return s.focus.indexOf(k) >= 0; };
    // Здоровье
    var dh = 0.03;
    if (a > 30) dh -= (a - 30) * 0.0045;
    if (a > 70) dh -= (a - 70) * 0.004;
    if (f.smoke) dh -= 0.12;
    if (f.drinks) dh -= 0.15;
    if (has('health')) dh += 0.35;
    if (f.sport) dh += 0.1;
    if (has('work') && s.job && Z.JOBS[s.job].stress >= 12) dh -= 0.06;
    st.hp = clamp(st.hp + dh, 0, 100);
    if (f.smoke) f.eversmoke = true;
    if (f.drinks) f.everdrink = true;
    // После 75 жизнь может тихо закончиться: чем старше и чем хуже здоровье, тем вероятнее
    if (a >= 75 && R.chance(0.0005 * (a - 74) + Math.max(0, 50 - st.hp) * 0.0004)) f.oldDeath = true;
    // Мастерство
    var cap = s.student ? 60 : 100;
    var dsk = has('work') ? 0.7 : 0.15;
    if (st.sk < cap) st.sk = clamp(st.sk + dsk, 0, cap);
    // Увлечение растит призвание
    if (has('self')) Object.keys(Z.HOBBY).forEach(function (h) { if (f['h_' + h]) Z.HOBBY[h].jobs.forEach(function (j) { s.fit[j] = clamp((s.fit[j] || 0) + 0.25, 0, 100); }); });
    // Достаток
    st.money = clamp(st.money + (Z.income(s) - st.money) * 0.06, 0, 100);
    // Отношения
    Object.keys(s.pp).forEach(function (id) {
      var p = s.pp[id]; if (!p.alive || !p.met) return;
      var d = 0;
      if (p.kind === 'parent') d = (has('parents') ? 1.2 : -0.22) - (f.abroad ? 0.15 : 0);
      else if (p.kind === 'kid') d = has('love') ? 1.0 : (has('work') ? -0.5 : -0.3);
      else if (p.kind === 'friend') {
        var close = Z.isClose(s, id);
        d = has('friends') ? (close ? 0.9 : 0.4) : (close ? -0.12 : -0.28);
        if (s.close.length >= 2 && !close && a > 26) d -= 0.1;
      } else if (p.kind === 'partner' && id === s.partner) {
        d = has('love') ? 1.0 : -0.45;
        if (has('work') && !has('love') && Z.married(s)) d -= 0.2;
        if (f.affair) d -= 0.4;
      }
      p.rel = clamp(p.rel + d, 0, 100);
    });
    // Счастье тянется к «базе», которую задают люди, работа, здоровье
    var base = Z.joyBase(s);
    st.joy = clamp(st.joy + (base - st.joy) * 0.1 + (R.rnd() - 0.5) * 1.6, 0, 100);
    if (s.grief > 0) s.grief--;
    if (s.job && !s.student) { s.jobM++; s.lvlM++; }
    if (s.partner) s.pMonths = (s.pMonths || 0) + 1;
  };

  // ---------- Выбор событий ----------
  Z.key = function (e, ctx) { return e.per ? e.id + ':' + (ctx && ctx[e.per]) : e.id; };
  Z.ok = function (s, e, ctx) {
    var a = Z.age(s);
    if (e.age && (a < e.age[0] || a >= e.age[1])) return false;
    var k = Z.key(e, ctx);
    if (e.once && s.seen[k] != null) return false;
    if (e.rep && s.seen[k] != null && s.m - s.seen[k] < e.rep) return false;
    if (e.gray && !Z.gray(s)) return false;
    if (e.samep && ctx && ctx.P && ctx.P !== s.partner) return false;
    if (s.f.inarmy && !e.army && !e.manual && Z.ARMY_OK.indexOf(e.id) < 0) return false;
    if (e.uni && !Z.uni(s)) return false;
    if (e.army && !s.f.inarmy) return false;
    if (e.if && !e.if(s, ctx || {})) return false;
    return true;
  };
  Z.ctxs = function (s, e) {
    if (!e.ctx) return [{}];
    var c = e.ctx(s);
    if (!c) return [];
    return Array.isArray(c) ? c : [c];
  };
  Z.candidates = function (s, e) {
    var all = Z.ctxs(s, e);
    return all.filter(function (c) { return Z.ok(s, e, c); });
  };
  Z.weight = function (s, e, ctx) {
    var w = typeof e.w === 'function' ? e.w(s, ctx) : (e.w == null ? 10 : e.w);
    if (e.gray) w *= 3;
    return w;
  };
  // Сколько месяцев в одном ходе: до 30 — 1, после 30 — 2, после 40 — 3, после 50 — 4.
  Z.step = function (s) { var a = Z.age(s); return a < 30 ? 1 : a < 40 ? 2 : a < 50 ? 3 : 4; };
  // Попадает ли в текущий ход один из месяцев (0 — январь … 11 — декабрь)
  Z.inMonth = function (s, mons) {
    var n = s.lastStep || 1;
    for (var k = 0; k < n; k++) if (mons.indexOf(Z.cal(s, s.m - k).mon) >= 0) return true;
    return false;
  };
  Z.density = function (s) {
    var a = Z.age(s);
    var d = a < 23 ? 0.75 : a < 30 ? 0.55 : a < 40 ? 0.7 : a < 50 ? 0.75 : 0.8;
    d *= { slow: 1.25, normal: 1, fast: 0.6 }[s.tempo] || 1;
    return d;
  };
  Z.pickRandom = function (s, n, taken) {
    var out = [];
    for (var k = 0; k < n; k++) {
      var pool = [], total = 0;
      Z.evList.forEach(function (e) {
        if (e.prio || e.manual) return;
        if (taken[e.id]) return;
        var cs = Z.candidates(s, e);
        if (!cs.length) return;
        var w = Z.weight(s, e, cs[0]);
        if (w <= 0) return;
        pool.push({ e: e, cs: cs, w: w }); total += w;
      });
      if (!pool.length) break;
      var r = R.rnd() * total, it = pool[0];
      for (var i = 0; i < pool.length; i++) { r -= pool[i].w; if (r <= 0) { it = pool[i]; break; } }
      taken[it.e.id] = true;
      out.push({ id: it.e.id, ctx: R.pick(it.cs) });
    }
    return out;
  };
  Z.forced = function (s, taken) {
    var out = [];
    // Запланированные
    var due = s.queue.filter(function (q) { return q.at <= s.m; });
    s.queue = s.queue.filter(function (q) { return q.at > s.m; });
    due.forEach(function (q) {
      var e = Z.EV[q.id]; if (!e) return;
      var ctx = q.ctx || (e.ctx ? Z.ctxs(s, e)[0] : {});
      if (!ctx) return;
      if (e.if && !e.if(s, ctx)) return;
      out.push({ id: q.id, ctx: ctx }); taken[q.id] = true;
    });
    // Обязательные (prio), самые важные первыми, не больше двух за месяц
    var pr = Z.evList.filter(function (e) { return e.prio && !taken[e.id]; })
      .map(function (e) { var cs = Z.candidates(s, e); return cs.length ? { e: e, c: cs[0] } : null; })
      .filter(Boolean).sort(function (x, y) { return y.e.prio - x.e.prio; }).slice(0, 2);
    pr.forEach(function (x) { out.push({ id: x.e.id, ctx: x.c }); taken[x.e.id] = true; });
    return out;
  };

  // Фраза о тихих месяцах
  Z.quietNote = function (s, from, to) {
    var a = Z.dateStr(s, from), b = Z.dateStr(s, to);
    var span = from === to ? Z.cap(a) : Z.cap(a) + ' — ' + b;
    var notes = s.focus.map(function (k) { return Z.FOCUS[k].note; }).join(', ');
    return span + ': жизнь идёт своим чередом — ' + notes + '.';
  };
  Z.GRAY_NOTES = [
    'Месяцы слиплись в один. Утро, дорога, вечер, экран, сон.',
    'Время шло мимо тебя, как поезд мимо полустанка.',
    'Ты почти не помнишь эти месяцы. Серое небо, серые дни.',
    'Ты жил на автопилоте. Звонки оставались без ответа.',
    'Дни были похожи друг на друга, как капли за окном.'
  ];

  // Новый ход: продвигаем время, собираем события месяца.
  Z.newTurn = function (s) {
    var t = { from: s.m, notes: [], q: [], i: 0 };
    var taken = {};
    var adv = function () { var n = Z.step(s); s.lastStep = n; for (var i = 0; i < n && !s.over; i++) { Z.tick(s); Z.checkEnd(s); } };
    if (s.started) adv();
    s.started = true;
    var quietFrom = null;
    for (var guard = 0; guard < 40 && !s.over; guard++) {
      Z.checkEnd(s);
      if (s.over) break;
      var forced = Z.forced(s, taken);
      if (forced.length) { t.q = t.q.concat(forced); }
      // Серый период — проматываем месяцы
      if (!forced.length && Z.gray(s) && !s.f.noskip && s.m > 6) {
        if (quietFrom != null) { t.notes.push(Z.quietNote(s, quietFrom, s.m - 1)); quietFrom = null; }
        var k = (s.st.joy < 15 ? R.int(6, 18) : R.int(2, 6)) * Math.max(1, Math.round(Z.step(s) / 1.5));
        if (Z.age(s) + k / 12 > s.endAge) k = Math.max(1, Math.floor((s.endAge - Z.age(s)) * 12));
        var from = s.m;
        for (var i = 0; i < k && !s.over; i++) { Z.tick(s); Z.checkEnd(s); }
        s.lastStep = Math.min(12, k);
        t.notes.push({ gray: true, t: Z.cap(Z.dateStr(s, from)) + ' — ' + Z.dateStr(s, s.m) + '. ' + R.pick(Z.GRAY_NOTES) + (k >= 12 ? ' Прошло больше года.' : '') });
        t.q = t.q.concat(Z.forced(s, taken));
        var life = Z.pickRandom(s, 1, taken);
        t.q = t.q.concat(life);
        if (t.q.length) break;
        continue;
      }
      // Сколько событий в этом месяце
      var n = 0;
      if (R.chance(Z.density(s))) n = 1;
      if (s.st.joy > 70 && R.chance(0.3)) n++;
      if (forced.length) n = Math.max(0, n - forced.length);
      if (n) t.q = t.q.concat(Z.pickRandom(s, n, taken));
      if (t.q.length) break;
      if (quietFrom == null) quietFrom = s.m - (s.lastStep || 1) + 1;
      adv();
    }
    if (quietFrom != null && quietFrom < s.m) t.notes.push(Z.quietNote(s, quietFrom, s.m - 1));
    t.to = s.m; t.span = s.lastStep || 1;
    s.turn = t;
    if (!s.over) Z.onTurn.forEach(function (fn) { fn(s, t); });
    return t;
  };

  Z.checkEnd = function (s) {
    if (s.over) return;
    if (s.st.hp <= 0) { s.over = Z.age(s) >= 70 ? 'old' : 'death'; return; }
    if (s.f.oldDeath) { s.over = 'old'; return; }
    if (Z.age(s) >= s.endAge && !s.f['end_' + s.endAge]) {
      s.f['end_' + s.endAge] = true;
      s.queue.unshift({ id: 'final_now', at: s.m });
    }
  };

  // Варианты события: каждый раз — другой текст. Использованные запоминаются, пока не кончатся все.
  Z.varsOf = function (s, e, ctx) {
    var v = typeof e.vars === 'function' ? e.vars(s, ctx || {}) : e.vars;
    return v || null;
  };
  Z.pickVar = function (s, inst) {
    var e = Z.EV[inst.id]; if (inst.v != null || !e.vars) return inst.v;
    var ctx = inst.ctx || {}, list = Z.varsOf(s, e, ctx);
    if (!list || !list.length) return null;
    var key = Z.key(e, ctx); s.vu = s.vu || {};
    var used = s.vu[key] || [];
    var ok = list.map(function (v, i) { return i; }).filter(function (i) { var v = list[i]; return !v.if || v.if(s, ctx); });
    if (!ok.length) ok = list.map(function (v, i) { return i; });
    var fresh = ok.filter(function (i) { return used.indexOf(i) < 0; });
    if (!fresh.length) { used = used.filter(function (i) { return ok.indexOf(i) < 0; }); fresh = ok; }
    var v = R.pick(fresh);
    used.push(v); s.vu[key] = used; inst.v = v;
    return v;
  };
  // Детерминированный генератор: случайности внутри карточки (какие варианты выбора показать) зависят только
  // от самой карточки — иначе на экране одни варианты, а при нажатии пересчитываются другие.
  Z.seeded = function (str) {
    var h = 1779033703 ^ str.length;
    for (var i = 0; i < str.length; i++) { h = Math.imul(h ^ str.charCodeAt(i), 3432918353); h = (h << 13) | (h >>> 19); }
    return function () { h = Math.imul(h ^ (h >>> 16), 2246822507); h = Math.imul(h ^ (h >>> 13), 3266489909); h ^= h >>> 16; return (h >>> 0) / 4294967296; };
  };
  Z.withSeed = function (seed, fn) {
    var old = R.rnd; R.rnd = Z.seeded(seed);
    try { return fn(); } finally { R.rnd = old; }
  };
  // Всё, что нужно показать карточке
  Z.view = function (s, inst) {
    if (inst.seed == null) inst.seed = s.m + ':' + Math.floor(R.rnd() * 1e9);
    return Z.withSeed(inst.id + '|' + inst.seed + '|' + JSON.stringify(inst.ctx || {}), function () { return Z.view0(s, inst); });
  };
  Z.view0 = function (s, inst) {
    var e = Z.EV[inst.id], ctx = inst.ctx || {};
    // Прожитая карточка показывается такой, какой была (состояние с тех пор изменилось)
    if (inst.done && inst.cache) return { e: e, ctx: ctx, title: inst.cache.title, text: inst.cache.text, choices: [] };
    var v = Z.pickVar(s, inst), V = v != null ? (Z.varsOf(s, e, ctx) || [])[v] : null;
    var out = {
      e: e, ctx: ctx,
      title: Z.t((V && V.title) || e.title || '', s, ctx),
      text: Z.t((V && V.t) || e.text, s, ctx),
      choices: Z.choicesOf(s, e, ctx, V)
    };
    inst.cache = { title: out.title, text: out.text };
    return out;
  };
  Z.choicesOf = function (s, e, ctx, V) {
    var src = V && V.c ? V.c : e.choices;
    var list = typeof src === 'function' ? src(s, ctx) : src;
    list = (list || []).filter(function (c) { return !c.if || c.if(s, ctx); });
    return list.length ? list : [{ t: 'Дальше', res: '' }];
  };

  Z.snapshot = function (s) {
    var r = {}; Object.keys(s.pp).forEach(function (id) { var p = s.pp[id]; if (p.met && p.alive) r[id] = p.rel; });
    return { st: JSON.parse(JSON.stringify(s.st)), r: r };
  };
  // В армии из обычной жизни доходит только это: звонки из дома и беды близких
  Z.ARMY_OK = ['pa_call', 'pa_dad_check', 'pa_dad_heart', 'pa_mom_sign', 'pa_mom_ill', 'p_breakup', 'p_wife_sign', 'p_wife_ill', 'o_parent_passing', 'fa_crash2', 'fa_depr2', 'fa_drink3', 'fa_ill2', 'fa_lost2', 'c_close'];
  // Студенческая жизнь в институте (не колледж, не армия, не аспирантура, не «забрал документы»)
  Z.uni = function (s) { return !!s.student && !s.f.noinst && !s.f.college && !s.f.gradschool && !s.f.inarmy; };
  Z.STAT_N = { hp: 'Здоровье', joy: 'Счастье', money: 'Достаток', sk: 'Мастерство' };
  Z.diff = function (s, a) {
    var out = [];
    Object.keys(Z.STAT_N).forEach(function (k) { var d = Math.round(s.st[k] - a.st[k]); if (d) out.push({ n: Z.STAT_N[k], d: d }); });
    Object.keys(s.pp).forEach(function (id) {
      var p = s.pp[id]; if (!p.met || !p.alive) return;
      var was = a.r[id] == null ? 0 : a.r[id];
      var d = Math.round(p.rel - was); if (d) out.push({ n: Z.cap(p.n), d: d, rel: true });
    });
    return out;
  };

  // Применить выбор
  Z.apply = function (s, ci, input) {
    var t = s.turn, inst = t.q[t.i], e = Z.EV[inst.id], ctx = inst.ctx || {};
    var V0 = Z.view(s, inst), c = V0.choices[ci];
    if (!c) c = { t: 'Дальше', res: '' };
    inst.opts = V0.choices.map(function (x) { return Z.t(x.t, s, ctx); });
    s.seen[Z.key(e, ctx)] = s.m;
    var snap = Z.snapshot(s);
    if (c.fx) Z.fx(s, c.fx, ctx);
    var r = c.run ? c.run(s, ctx, input) : null;
    var res = Z.t(r != null && r !== true ? r : c.res, s, ctx);
    if (c.log) Z.logLine(s, Z.t(c.log, s, ctx), c.lk);
    if (c.go) t.q.splice(t.i + 1, 0, { id: c.go, ctx: ctx });
    Z.checkEnd(s);
    inst.done = { res: res, d: Z.diff(s, snap), ci: ci };
    Z.onApply.forEach(function (fn) { fn(s, e, c, ctx, inst, inst.done); });
    return inst.done;
  };

  // Перейти к следующей карточке хода, пропуская ставшие неактуальными (например, после увольнения)
  Z.next = function (s) {
    var t = s.turn; t.i++;
    while (t.i < t.q.length) {
      var inst = t.q[t.i], e = Z.EV[inst.id];
      if (e.samep && inst.ctx && inst.ctx.P && inst.ctx.P !== s.partner) { t.i++; continue; }
      var armyBlock = (s.f.inarmy && !e.army && !e.manual && Z.ARMY_OK.indexOf(e.id) < 0) || (e.uni && !Z.uni(s));
      if (!armyBlock && (!e.if || e.if(s, inst.ctx || {}))) break;
      t.i++;
    }
    return t.i < t.q.length;
  };

  // Отложенный вызов событий (для арок): после этой карточки показать ещё одну
  Z.chain = function (s, id, ctx) { var t = s.turn; if (t) t.q.splice(t.i + 1, 0, { id: id, ctx: ctx || {} }); };
})();
