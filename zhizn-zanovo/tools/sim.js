// Прогон случайных жизней и проверки, чтобы игра не путала игрока.
// Запуск: node tools/sim.js [число жизней] [--verbose]
// Проверяет: ошибки кода, незаполненные шаблоны, род глаголов у детей и друзей, пол ребёнка и его имя,
// события о работе — только про нынешнюю работу, карьерный трек и мастерство при смене профессии,
// длину хода по возрасту, повторы одинаковых текстов, охват событий.
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm');
const root = path.join(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
const files = [...html.matchAll(/<script src="([^"]+)"/g)].map(m => m[1]).filter(f => !/ui\.js$/.test(f));
const warns = [];
const ctx = { console: { log: console.log, warn: m => warns.push(m), error: console.error }, Math, Date, JSON };
ctx.window = ctx;
vm.createContext(ctx);
for (const f of files) vm.runInContext(fs.readFileSync(path.join(root, f), 'utf8'), ctx, { filename: f });
const Z = ctx.Z;
Z.STRICT = true; // текст про жену, когда жены нет, — ошибка

const N = Number(process.argv[2] || 600);
const VERBOSE = process.argv.includes('--verbose');
const pick = a => a[Math.floor(Math.random() * a.length)];
const seen = {}, endings = {}, problems = [];
const stat = { mem: 0, repair: 0, news: 0, era: 0, pauses: 0, stranger: 0, forks: 0, army: 0, abroad: 0, noinst: 0, early: 0, chapters: 0 };
const achCount = {}; let cont = 0, to100 = 0; const oldAges = [];
let turns = 0, cards = 0, deaths = 0, totalGoals = 0, fixedGoals = 0, switches = 0, synergy = 0;
const repeatWorst = {}; // событие → худшее число повторов одного и того же текста в одной жизни
const cardsByTarget = {};

function randomSetup() {
  const su = { name: pick(['Андрей', 'Игорь', 'Саша', 'Илья']), age: pick([30, 40, 50, 60]), regrets: {} };
  su.married = pick(['never', 'married', 'divorced', 'widow']);
  if (su.married !== 'never') { su.wifeName = pick(['Наташа', 'Мария', 'Ольга', 'Юля', 'Любовь']); su.wifeType = pick(Object.keys(Z.PARTNERS)); }
  if (su.married === 'divorced') su.why = pick(['work', 'fights', 'goals', 'cheat', 'drink', 'other']);
  const ages = ['a', 'b', 'c', 'd'].filter(k => Z.RISK_AGE[k] < su.age);
  if (su.married === 'widow') su.wifeAge = pick(ages);
  su.kids = pick([0, 1, 2, 3]);
  su.parents = pick(['both', 'mom', 'dad', 'none']);
  su.dadAge = pick(ages); su.momAge = pick(ages);
  su.lostFriend = Math.random() < 0.5;
  if (su.lostFriend) { su.lostName = pick(['Вова', 'Света', 'Коля', 'Игорь']); su.lostFem = su.lostName === 'Света'; su.lostCause = pick(['crash', 'ill', 'drink', 'depr', 'lost']); }
  su.job = pick(Object.keys(Z.JOBS).concat([null]));
  Object.keys(Z.REGRETS).filter(() => Math.random() < 0.35).slice(0, 3).forEach(k => su.regrets[k] = true);
  su.tempo = pick(['slow', 'normal', 'fast']);
  su.values = Object.keys(Z.VALUES).sort(() => Math.random() - 0.5).slice(0, 3);
  return su;
}

const SEASON = [[/Картошку копать/, [7, 8]], [/Пасх/, [3, 4]], [/^Осень\./, [8, 9, 10]], [/^Весна\./, [2, 3, 4]], [/^Лето\./, [5, 6, 7]], [/Ночь, мороз/, [11, 0, 1, 2]]];
const WORK_ONLY = ['w_overtime', 'w_daily', 'w_dilemma', 'w_first_day', 'w_boss', 'w_burnout', 'w_headhunt', 'w_layoff', 'w_promo', 'w_mentor', 'w_ownbiz_solo', 'w_synergy', 'w_old_call', 'w_retire', 'fam_wife_career'].filter(id => id !== 'fam_wife_career');
const EMPLOYED_ONLY = ['w_boss', 'w_headhunt', 'w_layoff', 'w_ownbiz_solo', 'p_olga_meet'];
const KIDS_RE = /(твои дети|твоих детей|ваши дети|Дети |дети |детьми|внуков|внуки|внука |внучк|правнук|Ваш ребёнок)/;
const KIDS_OK = ['y_summer1', 'pa_anniv', 'y_internship', 'w_daily', 'w_dilemma', 'w_first_day', 'g_teach', 'fr_godparent', 'fr_serega_dad', 'f_help', 'f_reunion', 'k_birth', 'p_kids_talk', 'fam_empty', 'fa_pasha_debt', 'f_crisis', 'pa_story', 'o_great_grand'];
const YEARS = { 'пять': 5, 'десять': 10, 'пятнадцать': 15, 'двадцать': 20, 'тридцать': 30, 'сорок': 40 };
const YEARS_RE = /(пять|десять|пятнадцать|двадцать|тридцать|сорок) лет (назад|вместе|не виделись|не разговаривали)/gi;
function problem(msg) { problems.push(msg); }
function check(text, where) {
  if (/\{[^}]*\}/.test(text)) problem(where + ': незаполненный шаблон ' + text.match(/\{[^}]*\}/)[0] + ' — ' + text.slice(0, 80));
  if (/undefined|NaN|\[object|null/.test(text)) problem(where + ': ' + text.slice(0, 120));
}
// Род: «Маша пошёл», «Миша пришла» — имя и глагол прошедшего времени сразу после него
const MASC = /^[а-яё]{2,}(л|лся)$/i, FEM = /^[а-яё]{2,}(ла|лась)$/i;
const NOT_VERB = /^(стол|пол|посол|котёл|орёл|осёл|угол|зал|вокзал|сигнал|канал|финал|бал|идеал|материал|шла|пила|сила|мила|тела|дела|села|игла|скала|мгла|стрела|юла|была|мала|цела|бела|смела|весела|ила|гола|школа)$/i;
function genderCheck(text, s, c, where) {
  const keys = ['K', 'F', 'P', 'X', 'C1', 'C2'];
  const all = keys.map(k => Z.who(s, c, k)).filter(p => p && p.n);
  keys.forEach(k => {
    const p = Z.who(s, c, k); if (!p || !p.n) return;
    if (all.some(q => q !== p && q.n === p.n && q.fem !== p.fem)) return; // тёзки разного пола — не понять, о ком глагол
    const name = p.n; if (name.length < 2) return;
    const re = new RegExp('(^|[^А-Яа-яЁё])' + name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\s+([а-яё]+)', 'g');
    let m;
    while ((m = re.exec(text))) {
      const w = m[2];
      if (NOT_VERB.test(w)) continue;
      if (p.fem && MASC.test(w) && !FEM.test(w)) problem(`${where}: «${name} ${w}» — ${name} женского рода`);
      if (!p.fem && FEM.test(w)) problem(`${where}: «${name} ${w}» — ${name} мужского рода`);
    }
  });
}

// Самопроверка проверки рода
{
  const s0 = Z.newLife(randomSetup()); const k = Z.birth(s0, 'Миша', false); const before = problems.length;
  genderCheck('Миша пошла в школу.', s0, { K: k.id }, 'самопроверка');
  if (problems.length !== before + 1) { console.log('Проверка рода не работает'); process.exit(1); }
  problems.length = before;
  genderCheck(Z.t('{K} {K~пошёл|пошла} в школу.', s0, { K: k.id }), s0, { K: k.id }, 'самопроверка');
  if (problems.length !== before) { console.log('Проверка рода ругается зря'); process.exit(1); }
}

for (let n = 0; n < N; n++) {
  const su = randomSetup();
  const s = Z.newLife(su);
  const focuses = Object.keys(Z.FOCUS);
  const texts = {};
  let guard = 0, lastJob = null, lastSk = 0, lifeCards = 0, lifePauses = 0;
  try {
    while (!s.over && guard++ < 3000) {
      if (Math.random() < 0.08) { const a = pick(focuses); let b = pick(focuses); while (b === a) b = pick(focuses); s.focus = [a, b]; }
      const ageBefore = Z.age(s), stepWanted = Z.step(s);
      Z.newTurn(s); turns++;
      const t = s.turn;
      t.notes.forEach(n => { if (n && n.news) { stat.news++; check(n.t, 'новости'); genderCheck(n.t, s, {}, 'новости'); } if (n && n.era) { stat.era++; check(n.t, 'приметы'); } });
      // Длина хода: без серой перемотки ход равен шагу возраста (на границе возраста — шаг до или после)
      if (!t.notes.some(x => x && x.gray) && t.span !== stepWanted && t.span !== Z.step(s) && s.m > 1 && !s.over)
        problem(`ход длиной ${t.span} мес. в ${ageBefore.toFixed(1)} лет (ожидалось ${stepWanted})`);
      while (t.i < t.q.length && !s.over) {
        const inst = t.q[t.i], c = inst.ctx || {};
        const V = Z.view(s, inst);
        seen[inst.id] = (seen[inst.id] || 0) + 1; cards++; lifeCards++;
        check(V.text, inst.id); check(V.title, inst.id + ' заголовок');
        genderCheck(V.text, s, c, inst.id);
        V.choices.forEach(ch => { const ct = Z.t(ch.t, s, c); check(ct, inst.id + ' выбор'); genderCheck(ct, s, c, inst.id + ' выбор'); });
        // Работа: карточки про профессию — только про нынешнюю
        if (c.J && ['w_switch_doubt', 'w_retrain_done'].indexOf(inst.id) < 0 && c.J !== s.job) problem(`${inst.id}: карточка про «${Z.JOBS[c.J].n}», а работа сейчас «${s.job ? Z.JOBS[s.job].n : 'нет'}»`);
        if (inst.id === 'w_promo' && !V.text.includes(Z.JOBS[s.job].t[s.lvl + 1])) problem('w_promo: повышение не по нынешней профессии');
        if (inst.id === 'mem_back') stat.mem++;
        if (inst.id === 'r_repair') stat.repair++;
        if (inst.id === 'pause') { lifePauses++; stat.pauses++; }
        if (inst.id === 'stranger' || inst.id === 'stranger_reveal') stat.stranger++;
        if (inst.id === 'ch_start') stat.chapters++;
        // В армии — только армейское и самое важное
        const ev = Z.EV[inst.id];
        if (s.f.inarmy && !ev.army && !ev.manual && Z.ARMY_OK.indexOf(inst.id) < 0) problem(`${inst.id}: обычная карточка во время армии`);
        // Студенческая жизнь — только в институте; времена года; неуместные знакомства
        if (ev.uni && !Z.uni(s)) problem(`${inst.id}: студенческое событие, а ты не в институте`);
        const mons = []; for (let k = 0; k < (s.lastStep || 1); k++) mons.push(Z.cal(s, s.m - k).mon);
        SEASON.forEach(([re, ok]) => { if (re.test(V.text) && !mons.some(m => ok.indexOf(m) >= 0)) problem(`${inst.id}: «${V.text.match(re)[0]}» в ${Z.MONTHS[mons[0]]}`); });
        if (inst.id === 'p_meet_parents' && Z.married(s)) problem('p_meet_parents: знакомство с родителями после свадьбы');
        if (inst.id === 'pa_single_worry' && (s.partner || s.f.divorced)) problem('pa_single_worry: мама сватает при жене или после развода');
        if (inst.id === 'mem_back' && s.pp[c.X] && s.pp[c.X].kind === 'partner' && s.partner && c.X !== s.partner) problem('mem_back: воспоминание другой женщины при жене');
        if (inst.id === 'w_first_day' && s.jobAlt) problem('w_first_day: общий первый день вместо своего');
        // Варианты выбора не меняются между показом и нажатием
        const again = Z.view(s, inst).choices.map(ch => Z.t(ch.t, s, c)).join('|');
        if (again !== V.choices.map(ch => Z.t(ch.t, s, c)).join('|')) problem(inst.id + ': варианты выбора меняются между показом и нажатием');
        // Рабочие карточки — только когда работаешь (аспирантура — это учёба)
        if (WORK_ONLY.indexOf(inst.id) >= 0 && !Z.working(s)) problem(`${inst.id}: рабочая карточка, а работы нет (${s.f.gradschool ? 'аспирант' : s.student ? 'студент' : 'без работы'})`);
        if (EMPLOYED_ONLY.indexOf(inst.id) >= 0 && !Z.employed(s)) problem(`${inst.id}: карточка про начальство, а ты ${s.job ? Z.JOBS[s.job].n : 'без работы'}`);
        if (inst.id === 'w_offer' && s.job) problem('w_offer: поиск работы, а работа уже есть');
        // Дети и внуки в тексте, когда детей нет
        const kidsFree = Z.kids(s).length === 0;
        const kidsText = t => kidsFree && KIDS_RE.test(t) && KIDS_OK.indexOf(inst.id) < 0;
        if (kidsText(V.text)) problem(`${inst.id}: про детей/внуков, а детей нет — ${V.text.slice(0, 90)}`);
        // Сроки: «десять лет назад» в двадцать
        const yrs = (V.text.match(YEARS_RE) || []).map(w => YEARS[w.split(' ')[0].toLowerCase()]).filter(Boolean);
        yrs.forEach(n => { if (Z.age(s) - 18 < n) problem(`${inst.id}: «${n} лет» в тексте, а с восемнадцати прошло ${Math.floor(Z.age(s) - 18)} — ${V.text.slice(0, 80)}`); });
        // Повторы текста
        const key = inst.id + '|' + V.text;
        texts[key] = (texts[key] || 0) + 1;
        let ci = Math.floor(Math.random() * V.choices.length);
        if (inst.id === 'final_now') ci = Math.random() < 0.3 && V.choices.length > 1 ? 1 : 0;
        const input = V.e.ask ? pick(Z.KID_NAMES_M.concat(Z.KID_NAMES_F, ['Женя', 'Лука', 'Любовь'])) : null;
        const before = s.job, skBefore = s.st.sk;
        const label = Z.t(V.choices[ci].t, s, c);
        const d = Z.apply(s, ci, input);
        if (kidsText(d.res)) problem(`${inst.id} результат: про детей/внуков, а детей нет — ${d.res.slice(0, 90)}`);
        // Выбранная работа — та, что была написана на кнопке
        if ((inst.id === 'w_offer' || inst.id === 'y_internship') && s.job && inst.id === 'w_offer' && !/Подождать/.test(label)) {
          const want = label.replace(/ \(.*\)$/, '').toLowerCase();
          if (Z.JOBS[s.job].t[s.lvl].toLowerCase() !== want) problem(`w_offer: на кнопке «${label}», а получилась работа «${Z.JOBS[s.job].t[s.lvl]}»`);
        }
        check(d.res, inst.id + ' результат');
        // Как в интерфейсе: после выбора заново рисуются все карточки хода
        for (let j = 0; j <= t.i; j++) Z.view(s, t.q[j]);
        genderCheck(d.res, s, c, inst.id + ' результат');
        if (inst.id === 'w_synergy') synergy++;
        // Смена профессии: трек ведётся, мастерство не переносится целиком в чужую область
        if (s.job && s.job !== before) {
          const last = s.career[s.career.length - 1];
          if (!last || last.j !== s.job || last.to != null) problem('карьерный трек не записал новую работу ' + s.job);
          if (before) {
            switches++;
            const J = Z.JOBS[s.job], earlier = (s.career || []).slice(0, -1).map(c => c.j);
            const legit = earlier.some(j => Z.famShare(j, s.job)) || (s.degree && J.edu.indexOf(s.edu) >= 0) || (s.fit[s.job] || 0) >= 20 || s.f['re_' + s.job] || s.job === 'biz';
            if (!legit && s.st.sk > skBefore + 3) problem(`мастерство выросло при переходе ${before} → ${s.job} без опыта и диплома (${skBefore.toFixed(0)} → ${s.st.sk.toFixed(0)})`);
          }
        }
        Z.next(s);
      }
      // Дети: имя и пол не спорят
      Z.kids(s).forEach(k => { const g = Z.guessFem(k.n); if (g != null && g !== k.fem) problem(`ребёнок ${k.n} записан как ${k.fem ? 'дочь' : 'сын'}`); });
      if (s.job && s.job !== lastJob) { lastJob = s.job; lastSk = s.st.sk; }
    }
    if (!s.over) problem('Жизнь не закончилась: ' + JSON.stringify(s.setup));
    if (lifePauses > 3) problem('пауз-вопросов больше трёх: ' + lifePauses);
    stat.forks += Object.keys(s.forks || {}).length;
    if (s.f.army) stat.army++; if (s.f.abroad || s.f.abroadM != null) stat.abroad++; if (s.f.noinst) stat.noinst++; if (s.f.earlydad) stat.early++;
    const cmp = Z.compass(s); cmp.rows.forEach(r => check(r.n + r.word, 'компас')); check(cmp.text, 'компас');
    const E = Z.ending(s);
    E.paragraphs.concat(E.refl).forEach(p => check(p, 'итоги'));
    E.goals.forEach(g => check(g.t, 'цель'));
    E.compare.forEach(r => r.forEach(x => check(String(x), 'сравнение')));
    endings[E.title] = (endings[E.title] || 0) + 1;
    if (s.endAge === 100) { cont++; if (s.f.age100) to100++; else if (s.over === 'old' || s.over === 'death') oldAges.push(Z.ageInt(s)); }
    if (s.over === 'death' && Z.age(s) >= 70) problem('смерть после 70 должна быть «своей смертью», а не «оборвалась»');
    Z.achCheck(s, E).forEach(a => achCount[a] = (achCount[a] || 0) + 1);
    if (E.death) deaths++;
    totalGoals += E.goals.length; fixedGoals += E.fixed;
    (cardsByTarget[su.age] = cardsByTarget[su.age] || []).push(lifeCards);
    Object.entries(texts).forEach(([k, v]) => { const id = k.split('|')[0]; if (!repeatWorst[id] || repeatWorst[id] < v) repeatWorst[id] = v; });
  } catch (err) {
    problem('ОШИБКА: ' + err.stack.split('\n').slice(0, 3).join(' | '));
    if (problems.length > 60) break;
  }
}

const never = Z.evList.filter(e => !e.off).map(e => e.id).filter(id => !seen[id]);
console.log(`Жизней: ${N}, ходов в среднем: ${(turns / N).toFixed(0)}, карточек: ${(cards / N).toFixed(0)}, смертей: ${deaths}`);
console.log('Карточек за жизнь по возрасту игрока: ' + Object.keys(cardsByTarget).sort().map(a => `${a} лет — ${(cardsByTarget[a].reduce((x, y) => x + y, 0) / cardsByTarget[a].length).toFixed(0)}`).join(', '));
console.log(`Цели: исправлено ${fixedGoals} из ${totalGoals}. Смен профессии: ${switches}, «старый опыт пригодился»: ${synergy}`);
console.log(`Жили дальше: ${cont}, дожили до 100: ${to100}, остальные ушли в среднем в ${(oldAges.reduce((a, b) => a + b, 0) / Math.max(1, oldAges.length)).toFixed(0)} (от ${Math.min(...oldAges)} до ${Math.max(...oldAges)})`);
console.log('Достижения (сколько жизней получили): ' + Z.ACH.map(a => `${a.n} ${achCount[a.id] || 0}`).join(', '));
console.log(`Мир: напоминаний ${stat.mem}, примирений ${stat.repair}, «тем временем» ${stat.news}, примет времени ${stat.era}, пауз ${stat.pauses}, незнакомец ${stat.stranger}, глав ${stat.chapters}, развилок ${stat.forks}`);
console.log(`Большие развилки (жизней): армия ${stat.army}, заграница ${stat.abroad}, без института ${stat.noinst}, ранний ребёнок ${stat.early}`);
console.log('Концовки:', Object.entries(endings).sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k} ${v}`).join(', '));
console.log(`Событий: ${Z.evList.length}, ни разу не выпали (${never.length}): ${never.join(', ')}`);
// Семейные и дружеские события не должны повторять один и тот же текст больше двух раз за жизнь
const FAMILY = /^(pa_|f_|fr_|k_|fam_|p_)/;
const rep = Object.entries(repeatWorst).filter(([id]) => FAMILY.test(id)).sort((a, b) => b[1] - a[1]);
console.log('Худшие повторы одного текста за жизнь (семья/друзья): ' + rep.slice(0, 8).map(([k, v]) => `${k}×${v}`).join(', '));
rep.filter(([, v]) => v > 3).forEach(([k, v]) => problem(`повтор: ${k} — один и тот же текст ${v} раз за жизнь`));
const uniq = [...new Set(problems)];
const counts = {}; problems.forEach(p => counts[p] = (counts[p] || 0) + 1);
console.log(`Проблем: ${uniq.length}`); uniq.slice(0, VERBOSE ? 200 : 40).forEach(p => console.log(`  ${p}${counts[p] > 1 ? ' (×' + counts[p] + ')' : ''}`));
const uw = [...new Set(warns)]; if (uw.length) { console.log('Предупреждения:'); uw.slice(0, 20).forEach(w => console.log('  ' + w)); }
process.exit(uniq.length || uw.length ? 1 : 0);
