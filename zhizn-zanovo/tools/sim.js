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

const N = Number(process.argv[2] || 600);
const VERBOSE = process.argv.includes('--verbose');
const pick = a => a[Math.floor(Math.random() * a.length)];
const seen = {}, endings = {}, problems = [];
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
  return su;
}

function problem(msg) { problems.push(msg); }
function check(text, where) {
  if (/\{[^}]*\}/.test(text)) problem(where + ': незаполненный шаблон ' + text.match(/\{[^}]*\}/)[0] + ' — ' + text.slice(0, 80));
  if (/undefined|NaN|\[object|null/.test(text)) problem(where + ': ' + text.slice(0, 120));
}
// Род: «Маша пошёл», «Миша пришла» — имя и глагол прошедшего времени сразу после него
const MASC = /^[а-яё]{2,}(л|лся)$/i, FEM = /^[а-яё]{2,}(ла|лась)$/i;
const NOT_VERB = /^(стол|пол|посол|котёл|орёл|осёл|угол|зал|вокзал|сигнал|канал|финал|бал|идеал|материал|шла|пила|сила|мила|тела|дела|села|игла|скала|мгла|стрела|юла|была|мала|цела|бела|смела|весела|ила|гола|школа)$/i;
function genderCheck(text, s, c, where) {
  ['K', 'F', 'P', 'X', 'C1', 'C2'].forEach(k => {
    const p = Z.who(s, c, k); if (!p || !p.n) return;
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
  let guard = 0, lastJob = null, lastSk = 0, lifeCards = 0;
  try {
    while (!s.over && guard++ < 3000) {
      if (Math.random() < 0.08) { const a = pick(focuses); let b = pick(focuses); while (b === a) b = pick(focuses); s.focus = [a, b]; }
      const ageBefore = Z.age(s), stepWanted = Z.step(s);
      Z.newTurn(s); turns++;
      const t = s.turn;
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
        // Повторы текста
        const key = inst.id + '|' + V.text;
        texts[key] = (texts[key] || 0) + 1;
        let ci = Math.floor(Math.random() * V.choices.length);
        if (inst.id === 'final_now') ci = Math.random() < 0.3 && V.choices.length > 1 ? 1 : 0;
        const input = V.e.ask ? pick(Z.KID_NAMES_M.concat(Z.KID_NAMES_F, ['Женя', 'Лука', 'Любовь'])) : null;
        const before = s.job, skBefore = s.st.sk;
        const d = Z.apply(s, ci, input);
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
            const legit = earlier.some(j => Z.famShare(j, s.job)) || (s.degree && J.edu.indexOf(s.edu) >= 0) || (s.fit[s.job] || 0) >= 20 || s.f['re_' + s.job];
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
    const E = Z.ending(s);
    E.paragraphs.concat(E.refl).forEach(p => check(p, 'итоги'));
    E.goals.forEach(g => check(g.t, 'цель'));
    E.compare.forEach(r => r.forEach(x => check(String(x), 'сравнение')));
    endings[E.title] = (endings[E.title] || 0) + 1;
    if (E.death) deaths++;
    totalGoals += E.goals.length; fixedGoals += E.fixed;
    (cardsByTarget[su.age] = cardsByTarget[su.age] || []).push(lifeCards);
    Object.entries(texts).forEach(([k, v]) => { const id = k.split('|')[0]; if (!repeatWorst[id] || repeatWorst[id] < v) repeatWorst[id] = v; });
  } catch (err) {
    problem('ОШИБКА: ' + err.stack.split('\n').slice(0, 3).join(' | '));
    if (problems.length > 60) break;
  }
}

const never = Z.evList.map(e => e.id).filter(id => !seen[id]);
console.log(`Жизней: ${N}, ходов в среднем: ${(turns / N).toFixed(0)}, карточек: ${(cards / N).toFixed(0)}, смертей: ${deaths}`);
console.log('Карточек за жизнь по возрасту игрока: ' + Object.keys(cardsByTarget).sort().map(a => `${a} лет — ${(cardsByTarget[a].reduce((x, y) => x + y, 0) / cardsByTarget[a].length).toFixed(0)}`).join(', '));
console.log(`Цели: исправлено ${fixedGoals} из ${totalGoals}. Смен профессии: ${switches}, «старый опыт пригодился»: ${synergy}`);
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
