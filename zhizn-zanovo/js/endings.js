// Итоги жизни: концовки, сравнение «тогда и сейчас», что взять с собой.
(function () {
  'use strict';
  var Z = window.Z;

  var ARCH = {
    family:   { t: 'Хранитель очага', d: 'Ты построил дом, в который хочется возвращаться. Твоё главное дело — люди за твоим столом.' },
    calling:  { t: 'Мастер своего дела', d: 'Ты нашёл работу, которую любишь, и стал в ней лучшим. Понедельники перестали быть наказанием.' },
    artist:   { t: 'Художник своей жизни', d: 'Ты решился делать то, что любишь, — и это стало твоей жизнью.' },
    builder:  { t: 'Строитель', d: 'Ты рискнул и построил своё. То, на что не решился в прошлый раз.' },
    friend:   { t: 'Верный друг', d: 'Ты оказался рядом, когда это было нужнее всего. Кто-то жив благодаря тебе.' },
    son:      { t: 'Сын, который успел', d: 'Ты успел то, что не успел в прошлой жизни: быть рядом с родителями, пока они живы.' },
    healer:   { t: 'Тот, кто помогал', d: 'Ты прожил жизнь, помогая другим. Чужие спасённые дни — твоё наследство.' },
    free:     { t: 'Свободный человек', d: 'Ты прожил жизнь по своим правилам — и тебе в ней хорошо, даже в тишине.' },
    worker:   { t: 'Человек дела', d: 'Ты многого добился. Но иногда, в пустой квартире, ты слышишь, как тикают часы.' },
    lonely:   { t: 'Одинокий путник', d: 'Жизнь прошла мимо — снова. Но то, что ты это видишь, — уже начало перемен.' },
    happy:    { t: 'Счастливый человек', d: 'Не идеальная жизнь — но твоя. Полная людей, смысла и простых радостей.' },
    repeat:   { t: 'Та же жизнь — другими глазами', d: 'Ты прошёл почти той же дорогой. Но на этот раз — смотрел по сторонам и ценил каждый шаг.' }
  };

  function avg(arr) { return arr.length ? arr.reduce(function (a, b) { return a + b; }, 0) / arr.length : 0; }

  Z.facts = function (s) {
    var f = {};
    f.age = Z.ageInt(s);
    f.P = Z.P(s);
    f.married = Z.married(s);
    f.divorces = s.cnt.divorce || 0;
    f.widower = !!s.f.widower && !s.partner;
    f.kids = Z.kids(s);
    f.kidRel = avg(f.kids.map(function (k) { return k.rel; }));
    f.parents = Z.parentsAlive(s);
    f.parRel = avg(['mom', 'dad'].map(function (id) { return s.pp[id].rel; }));
    f.savedParents = ['mom', 'dad'].filter(function (id) { return s.risk[id] === null && s.pp[id].alive; });
    f.lostParents = ['mom', 'dad'].filter(function (id) { return !s.pp[id].alive; });
    f.close = s.close.filter(function (id) { return s.pp[id].alive && !s.pp[id].gone; });
    var rf = s.risk.friend;
    f.riskFriend = rf ? s.pp[rf.id] : null;
    f.savedFriend = !!(rf && s.pp[rf.id].alive && !s.pp[rf.id].gone && s.pp[rf.id].met);
    f.friendsCount = Z.friendIds(s).filter(function (id) { return s.pp[id].rel >= 30; }).length;
    f.job = s.job; f.lvl = s.lvl; f.fit = s.job ? (s.fit[s.job] || 0) : 0;
    f.sameJob = s.job && s.job === s.setup.job;
    f.wifeSame = s.f.pastwife && s.partner === s.f.pastwife;
    f.savedWife = s.setup.married === 'widow' && s.f.pastwife && s.pp[s.f.pastwife].alive && s.partner === s.f.pastwife;
    if (!s.job && Z.age(s) >= 63) s.f.retired = true;
    f.hp = s.st.hp; f.joy = s.st.joy; f.money = s.st.money;
    return f;
  };

  Z.goals = function (s, f) {
    var R = s.setup.regrets || {}, out = [];
    function g(k, ok, yes, no) { if (R[k]) out.push({ k: k, n: Z.REGRETS[k], ok: ok, t: ok ? yes : no }); }
    g('parents', f.parRel >= 65 || f.savedParents.length > 0 || (s.cnt.parentvisit || 0) >= 8,
      f.savedParents.length ? 'Ты не просто был рядом — ты продлил им жизнь.' : 'Ты был рядом. Звонил, приезжал, слушал.',
      'Снова не хватило времени. Работа, дела, «потом».');
    g('calling', !!s.job && f.fit >= 25 && (!f.sameJob || f.fit >= 35),
      f.sameJob ? 'Ты вернулся к прежнему делу — но теперь любишь его.' : 'Ты нашёл своё дело: ' + Z.jobName(s) + '.',
      'Своё дело так и не нашлось. Пока.');
    g('love', (f.married || Z.dating(s)) && f.P && f.P.rel >= 60,
      'Рядом — {P}. Вы сберегли друг друга.', f.divorces ? 'Любовь снова не удержалась.' : 'Любовь так и не случилась — или не задержалась.');
    g('family', f.kids.length > 0 && f.kidRel >= 55,
      'Твои дети тебя любят и знают. Ты был рядом, когда это было важно.', f.kids.length ? 'Дети выросли — но немного без тебя.' : 'Детей в этой жизни не случилось.');
    g('health', (f.hp >= 55 || (f.age >= 75 && f.hp >= 25)) && !s.f.smoke && !s.f.drinks,
      f.age >= 75 ? 'Ты сберёг себя — и прожил долгую жизнь без вредных привычек.' : 'Ты сберёг себя. Тело благодарит каждое утро.', 'Здоровье снова ушло на второй план.');
    g('friends', f.close.length >= 2 || (f.close.length >= 1 && f.savedFriend),
      f.savedFriend ? 'Друг, которого ты потерял в прошлой жизни, — жив и рядом.' : 'Рядом друзья, которым можно позвонить в три часа ночи.',
      'Друзья растворились в годах.');
    g('courage', !!(s.f.brave),
      'Ты рискнул. Не всё получилось — но ты больше не живёшь с «а если бы».', 'Ты снова выбрал безопасную дорогу.');
    g('money', f.money >= 50,
      'Ты больше не считаешь копейки до зарплаты.', 'Денег по-прежнему не хватает.');
    return out;
  };

  Z.archetype = function (s, f) {
    var sc = {};
    sc.family = (f.married && f.P.rel >= 60 ? 3 : 0) + (f.kids.length && f.kidRel >= 60 ? 3 : 0);
    sc.calling = f.fit >= 30 ? 2 + f.lvl : 0;
    sc.artist = ['writer', 'music', 'photo', 'design', 'actor', 'carpenter'].indexOf(f.job) >= 0 && f.fit >= 35 ? 6 : 0;
    sc.builder = (s.f.ownbiz || s.f.ownjob) && f.money >= 55 ? 5 : 0;
    sc.friend = (f.savedFriend && s.risk.friend ? 4 : 0) + (f.close.length >= 2 ? 2 : 0);
    sc.son = f.savedParents.length * 3 + (f.parRel >= 75 ? 2 : 0);
    sc.healer = (['doctor', 'psych', 'rescue', 'teacher', 'nurse', 'social', 'vet', 'coach'].indexOf(f.job) >= 0 && f.fit >= 25 ? 3 : 0) + (s.f.volunteer ? 2 : 0) + (s.f.mentor ? 1 : 0);
    sc.free = !s.partner && s.f.content_alone && f.joy >= 55 ? 5 : 0;
    sc.worker = f.lvl >= 3 && (!f.P || f.P.rel < 45) ? 5 : 0;
    sc.lonely = f.joy < 35 && !s.partner && f.close.length === 0 ? 7 : 0;
    sc.repeat = f.sameJob && f.wifeSame ? 6 : 0;
    sc.happy = f.joy >= 72 ? 5 : 0;
    var best = 'happy', bv = -1;
    Object.keys(sc).forEach(function (k) { if (sc[k] > bv) { bv = sc[k]; best = k; } });
    if (bv <= 0) best = f.joy >= 50 ? 'happy' : 'lonely';
    return best;
  };

  function pastFamily(su) {
    var m = { never: 'Не был женат', married: 'Женат', divorced: 'Разведён', widow: 'Вдовец' }[su.married] || '—';
    if (su.wifeName && su.married !== 'never') m += ' (' + su.wifeName + ')';
    return m;
  }

  Z.ending = function (s) {
    var f = Z.facts(s), su = s.setup;
    var arch = s.over === 'death' ? null : Z.archetype(s, f);
    var P = [];
    if (s.over === 'death') {
      P.push('Жизнь оборвалась в ' + f.age + '. Раньше, чем хотелось. Здоровье — то, что в обеих жизнях откладывалось «на потом».');
    } else {
      if (s.over === 'old') P.push('Ты ушёл в ' + Z.yearsStr(f.age) + ' — тихо, своей смертью' + (f.age >= s.setup.age + 10 ? ', прожив гораздо дольше, чем в прошлый раз' : '') + '.');
      var d = ARCH[arch].d;
      if (arch === 'friend' && !(f.savedFriend && s.risk.friend)) d = 'Ты сберёг дружбу, которая выдержала годы. Рядом люди, которые придут по первому звонку — и к которым придёшь ты.';
      P.push(d);
    }
    // Любовь
    if (f.married) P.push(Z.t('{P} рядом уже ' + Z.yearsStr(Math.max(1, Math.floor(Z.yearsMarried(s)))) + '.', s) + (f.wifeSame ? ' Ты снова выбрал её — и на этот раз сумел сберечь.' : (s.f.pastwife ? ' В этой жизни ты выбрал другую дорогу.' : '')) + (f.savedWife ? ' Она жива. Ты успел.' : ''));
    else if (f.widower) P.push('Ты потерял жену. Эта боль — с тобой. Но и любовь — тоже.');
    else if (f.divorces) P.push('Брак не сохранился. Но ты многое понял о себе и о любви.');
    else P.push(s.f.content_alone ? 'Ты так и не женился — и научился быть счастливым в своей тишине.' : 'Своей семьи ты так и не создал.');
    // Дети
    if (f.kids.length) {
      var names = f.kids.map(function (k) { return k.n; }).join(', ');
      P.push((f.kids.length === 1 ? 'Ребёнок — ' : 'Дети — ') + names + '. ' + (f.kidRel >= 65 ? 'Они звонят просто так и приезжают с внуками. Ты был им не только кошельком, но и отцом.' : f.kidRel >= 45 ? 'Вы близки — не всегда, но по-настоящему.' : 'Между вами — дистанция. Её ещё можно сократить.'));
    }
    // Родители
    if (f.savedParents.length) P.push(f.savedParents.length === 2 ? 'Мама и папа живы. Ты подарил им годы, которых в прошлой жизни у них не было.' : (f.savedParents[0] === 'mom' ? 'Мама' : 'Папа') + ' жив' + (f.savedParents[0] === 'mom' ? 'а' : '') + ' — в этой жизни ты успел вовремя.');
    else if (f.parents.length === 2) P.push(f.parRel >= 65 ? 'Родители живы, и ты знаешь их — их истории, их страхи, их любовь.' : 'Родители живы. Но звонишь ты им по-прежнему редко.');
    else if (f.lostParents.length) P.push(f.parRel >= 60 ? 'Родителей уже нет — но ты был рядом и сказал всё, что хотел.' : 'Родителей уже нет. Многое осталось несказанным.');
    // Друзья
    if (f.savedFriend && f.riskFriend) P.push(Z.t('{X} жив{X~|а}. Каждый раз, когда вы встречаетесь, ты украдкой смотришь на {X~него|неё} — и не можешь поверить.', s, { X: f.riskFriend.id }));
    else if (f.riskFriend && !f.riskFriend.alive) P.push(Z.t('{X} снова ушёл. Ты пытался — и это главное, что можно было сделать.', s, { X: f.riskFriend.id }).replace('ушёл', f.riskFriend.fem ? 'ушла' : 'ушёл'));
    if (f.close.length >= 2) P.push(Z.t('Самые близкие друзья — {C1} и {C2}. Двое, на кого можно положиться всегда.', s));
    else if (f.close.length === 1) P.push(Z.t('Рядом остал{C1~ся|ась} {C1} — друг на всю жизнь.', s));
    // Работа
    var track = Z.trackStr(s), nJobs = (track.match(/→/g) || []).length + 1;
    if (s.job) P.push('Работа: ' + Z.jobTitle(s) + '. ' + (f.fit >= 30 ? 'Ты её любишь.' : f.fit >= 15 ? 'Она тебе нравится.' : 'Она кормит, но не греет.') + (nJobs > 1 ? ' Твой путь: ' + track + '. ' + (s.f.switched_field ? 'Ты не побоялся начать с нуля — и опыт прежних дел остался с тобой.' : '') : ''));
    else if (nJobs > 1 || (s.career || []).length) P.push('Твой путь в работе: ' + track + '.');
    else if (s.f.retired) P.push('Ты на пенсии. У тебя наконец есть время.');

    var goals = Z.goals(s, f).map(function (g) { g.t = Z.t(g.t, s); return g; });
    var fixed = goals.filter(function (g) { return g.ok; }).length;

    var compare = [
      ['Семья', pastFamily(su), f.married ? Z.t('Женат ({P})', s) : f.widower ? 'Вдовец' : f.divorces ? 'Разведён' : 'Не женат'],
      ['Дети', su.kids ? String(su.kids === 3 ? '3 и больше' : su.kids) : 'Нет', f.kids.length ? String(f.kids.length) : 'Нет'],
      ['Родители', { both: 'Оба живы', mom: 'Жива мама', dad: 'Жив папа', none: 'Их уже нет' }[su.parents] || '—',
        f.parents.length === 2 ? 'Оба живы' : f.parents.length ? (f.parents[0] === 'mom' ? 'Жива мама' : 'Жив папа') : 'Их уже нет'],
      ['Друзья', su.lostFriend ? 'Потерял друга' : 'Все рядом', f.riskFriend ? (f.savedFriend ? Z.t('{X} — рядом', s, { X: f.riskFriend.id }) : 'Не удержал') : (f.close.length + ' ' + Z.plural(f.close.length, 'близкий', 'близких', 'близких'))],
      ['Работа', su.job && Z.JOBS[su.job] ? Z.cap(Z.JOBS[su.job].n) : 'Другое', Z.trackStr(s) ? Z.cap(Z.trackStr(s)) + (s.job ? '' : s.f.retired ? ' (пенсия)' : ' (сейчас без работы)') : (s.f.retired ? 'Пенсия' : 'Без работы')]
    ];

    // Что взять в настоящую жизнь
    var refl = [];
    var R = su.regrets || {};
    if (R.parents) refl.push(su.parents === 'none' ? 'Вспомни родителей сегодня — их голоса, их руки. Расскажи о них своим детям или запиши то, что помнишь.' : 'Позвони родителям сегодня. Не по делу — просто спроси, как они. И спроси о их молодости.');
    if (R.friends || su.lostFriend) refl.push('Напиши другу, с которым давно не говорил. Одно сообщение может изменить больше, чем кажется. Если кому-то из близких тяжело — не жди, пока позовут.');
    if (R.love) refl.push(su.married === 'married' ? 'Сегодня вечером скажи жене одну вещь, за которую ты ей благодарен. Не завтра.' : 'Любовь начинается с того, чтобы выйти из дома. Сходи туда, где бывают новые люди.');
    if (R.family) refl.push(su.kids ? 'Проведи с детьми час без телефона. Спроси, чего они боятся и о чём мечтают.' : 'Семья — это не только дети. Кто те люди, кого ты называешь своими? Скажи им об этом.');
    if (R.calling) refl.push('Вспомни, от какого дела ты забывал о времени. Удели ему один вечер на этой неделе. Сорок, пятьдесят, шестьдесят — не поздно.');
    if (R.health) refl.push('Запишись к врачу, которого откладываешь. И выйди сегодня пройтись — просто так, двадцать минут.');
    if (R.courage) refl.push('Назови одно «а если бы», которое тебя мучает. Какой самый маленький шаг к нему можно сделать на этой неделе?');
    if (R.money) refl.push('Деньги — это спокойствие, а не цифра. Что тебе на самом деле нужно, чтобы спать спокойно? Начни с одного шага.');
    if (!refl.length) refl.push('Подумай: какой выбор из этой игры ты хотел бы сделать в настоящей жизни? Он всё ещё возможен — в какой-то форме.');
    refl.push('Прошлое не переписать. Но каждый день — это новый первый курс. Сегодня ты моложе, чем будешь когда-либо.');

    return {
      death: s.over === 'death',
      title: s.over === 'death' ? 'Жизнь оборвалась' : ARCH[arch].t,
      age: f.age, old: s.over === 'old', paragraphs: P, goals: goals, fixed: fixed, compare: compare, refl: refl.slice(0, 4)
    };
  };
})();
