// Прогон случайных жизней: ошибки, незаполненные шаблоны, охват событий, длина игры, концовки.
// Запуск: node tools/sim.js [число жизней]
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
const pick = a => a[Math.floor(Math.random() * a.length)];
const seen = {}, endings = {}, problems = [];
let turns = 0, cards = 0, deaths = 0, totalGoals = 0, fixedGoals = 0;

function randomSetup() {
  const su = { name: pick(['Андрей', 'Игорь', 'Саша', 'Илья']), age: pick([30, 40, 50, 60]), regrets: {} };
  su.married = pick(['never', 'married', 'divorced', 'widow']);
  if (su.married !== 'never') { su.wifeName = pick(['Наташа', 'Мария', 'Ольга', 'Юля']); su.wifeType = pick(Object.keys(Z.PARTNERS)); }
  if (su.married === 'divorced') su.why = pick(['work', 'fights', 'goals', 'cheat', 'drink', 'other']);
  const ages = ['a', 'b', 'c', 'd'].filter(k => Z.RISK_AGE[k] < su.age);
  if (su.married === 'widow') su.wifeAge = pick(ages);
  su.kids = pick([0, 1, 2, 3]);
  su.parents = pick(['both', 'mom', 'dad', 'none']);
  su.dadAge = pick(ages); su.momAge = pick(ages);
  su.lostFriend = Math.random() < 0.5;
  if (su.lostFriend) { su.lostName = pick(['Вова', 'Света', 'Коля']); su.lostFem = su.lostName === 'Света'; su.lostCause = pick(['crash', 'ill', 'drink', 'depr', 'lost']); }
  su.job = pick(Object.keys(Z.JOBS).concat([null]));
  Object.keys(Z.REGRETS).filter(() => Math.random() < 0.35).slice(0, 3).forEach(k => su.regrets[k] = true);
  su.tempo = pick(['slow', 'normal', 'fast']);
  return su;
}
function check(text, where) {
  if (/\{[^}]*\}/.test(text)) problems.push(where + ': незаполнено: ' + text.match(/\{[^}]*\}/)[0] + ' — ' + text.slice(0, 80));
  if (/undefined|NaN|\[object/.test(text)) problems.push(where + ': ' + text.slice(0, 120));
}

for (let n = 0; n < N; n++) {
  const s = Z.newLife(randomSetup());
  const focuses = Object.keys(Z.FOCUS);
  let guard = 0;
  try {
    while (!s.over && guard++ < 3000) {
      if (Math.random() < 0.08) { const a = pick(focuses); let b = pick(focuses); while (b === a) b = pick(focuses); s.focus = [a, b]; }
      Z.newTurn(s); turns++;
      const t = s.turn;
      while (t.i < t.q.length && !s.over) {
        const inst = t.q[t.i], e = Z.EV[inst.id];
        seen[inst.id] = (seen[inst.id] || 0) + 1; cards++;
        check(Z.t(e.text, s, inst.ctx || {}), inst.id);
        if (e.title) check(Z.t(e.title, s, inst.ctx || {}), inst.id + ' title');
        const ch = Z.choicesOf(s, e, inst.ctx || {});
        ch.forEach(c => check(Z.t(c.t, s, inst.ctx || {}), inst.id + ' choice'));
        let ci = Math.floor(Math.random() * ch.length);
        if (inst.id === 'final_now') ci = Math.random() < 0.3 && ch.length > 1 ? 1 : 0;
        const d = Z.apply(s, ci, null);
        check(d.res, inst.id + ' res');
        Z.next(s);
      }
    }
    if (!s.over) problems.push('Жизнь не закончилась: ' + JSON.stringify(s.setup));
    const E = Z.ending(s);
    E.paragraphs.concat(E.refl).forEach(p => check(p, 'ending'));
    E.goals.forEach(g => check(g.t, 'goal'));
    endings[E.title] = (endings[E.title] || 0) + 1;
    if (E.death) deaths++;
    totalGoals += E.goals.length; fixedGoals += E.fixed;
  } catch (err) {
    problems.push('ОШИБКА: ' + err.stack.split('\n').slice(0, 3).join(' | '));
    if (problems.length > 30) break;
  }
}

const never = Z.evList.map(e => e.id).filter(id => !seen[id]);
console.log(`Жизней: ${N}, ходов в среднем: ${(turns / N).toFixed(0)}, карточек: ${(cards / N).toFixed(0)}, смертей: ${deaths}`);
console.log(`Цели: исправлено ${fixedGoals} из ${totalGoals}`);
console.log('Концовки:', Object.entries(endings).sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k} ${v}`).join(', '));
console.log(`Событий: ${Z.evList.length}, ни разу не выпали (${never.length}): ${never.join(', ')}`);
const uniq = [...new Set(problems)];
console.log(`Проблем: ${uniq.length}`); uniq.slice(0, 40).forEach(p => console.log('  ' + p));
const uw = [...new Set(warns)]; if (uw.length) { console.log('Предупреждения:'); uw.slice(0, 20).forEach(w => console.log('  ' + w)); }
process.exit(uniq.length || uw.length ? 1 : 0);
