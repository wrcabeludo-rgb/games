// Интерфейс: экраны, карточки событий, сохранение.
(function () {
  'use strict';
  var Z = window.Z;
  var KEY = 'zhizn_zanovo_save_v1';
  var S = null;           // состояние жизни
  var view = 'life';      // life | people | log
  var su = null, stepI = 0; // анкета
  var app;

  function esc(t) { return String(t).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function paras(t) { return String(t).split(/\n\n+/).map(function (p) { return '<p>' + esc(p).replace(/\n/g, '<br>') + '</p>'; }).join(''); }
  function save() { try { localStorage.setItem(KEY, JSON.stringify(S)); } catch (e) { /* приватный режим */ } }
  function load() { try { var t = localStorage.getItem(KEY); return t ? JSON.parse(t) : null; } catch (e) { return null; } }
  function clearSave() { try { localStorage.removeItem(KEY); } catch (e) { } }
  function h(sel) { return app.querySelector(sel); }
  function scrollTop() { window.scrollTo(0, 0); }

  // ---------- Титульный экран ----------
  function title() {
    var saved = load();
    app.innerHTML =
      '<div class="title">' +
      '<div class="sun"></div>' +
      '<h1>Жизнь<br>заново</h1>' +
      '<p class="tag">Ты просыпаешься в восемнадцать. Родители живы. Всё ещё впереди.<br>Что ты сделаешь иначе?</p>' +
      (saved && !saved.over ? '<button class="btn primary" id="cont">Продолжить жизнь<small>' + esc(saved.setup.name) + ', ' + Z.ageInt(saved) + ' ' + Z.plural(Z.ageInt(saved), 'год', 'года', 'лет') + '</small></button>' : '') +
      '<button class="btn ' + (saved && !saved.over ? '' : 'primary') + '" id="new">Новая жизнь</button>' +
      '<p class="fine">Это игра о втором шансе. Она не заменяет помощь специалиста — но может помочь задуматься о главном.</p>' +
      '</div>';
    if (h('#cont')) h('#cont').onclick = function () { S = saved; migrate(S); view = 'life'; render(); };
    h('#new').onclick = function () {
      if (saved && !saved.over && !confirm('Начать новую жизнь? Текущая будет стёрта.')) return;
      su = { regrets: {} }; stepI = 0; setupScreen();
    };
  }
  function migrate(s) { if (!s.cnt) s.cnt = {}; if (!s.endAge) s.endAge = s.target; }

  // ---------- Анкета ----------
  function setupScreen() {
    var steps = Z.setupSteps(su);
    if (stepI >= steps.length) return intro();
    var st = steps[stepI];
    var html = '<div class="setup"><div class="prog"><i style="width:' + Math.round(stepI / steps.length * 100) + '%"></i></div>' +
      '<p class="kicker">Прошлая жизнь</p><h2>' + esc(st.q) + '</h2>' + (st.hint ? '<p class="hint">' + esc(st.hint) + '</p>' : '');
    if (st.type === 'text') {
      html += '<input class="inp" id="ti" maxlength="20" autocomplete="off" placeholder="' + esc(st.ph || '') + '" value="' + esc(su[st.k] || '') + '">' +
        '<button class="btn primary" id="tn">Дальше</button>';
    } else {
      var opts = Z.stepOpts(st, su);
      html += '<div class="opts' + (st.grid ? ' grid' : '') + '">' + opts.map(function (o, i) {
        var on = st.type === 'multi' ? !!su.regrets[o[0]] : su[st.k] === o[0];
        return '<button class="opt' + (on ? ' on' : '') + '" data-i="' + i + '">' + esc(o[1]) + '</button>';
      }).join('') + '</div>';
      if (st.type === 'multi') html += '<button class="btn primary" id="tn">Дальше</button>';
    }
    if (stepI > 0) html += '<button class="btn ghost" id="back">← Назад</button>';
    html += '</div>';
    app.innerHTML = html; scrollTop();
    if (h('#back')) h('#back').onclick = function () { stepI--; setupScreen(); };
    if (st.type === 'text') {
      var inp = h('#ti');
      var go = function () { su[st.k] = inp.value.trim() || st.ph; if (st.k === 'name' && su[st.k] === 'Андрей' && !inp.value.trim()) su.name = 'Андрей'; stepI++; setupScreen(); };
      h('#tn').onclick = go; inp.onkeydown = function (e) { if (e.key === 'Enter') go(); };
      setTimeout(function () { inp.focus(); }, 50);
    } else {
      var opts2 = Z.stepOpts(st, su);
      app.querySelectorAll('.opt').forEach(function (b) {
        b.onclick = function () {
          var v = opts2[+b.dataset.i][0];
          if (st.type === 'multi') {
            if (su.regrets[v]) delete su.regrets[v];
            else if (Object.keys(su.regrets).length < st.max) su.regrets[v] = true;
            setupScreen(); return;
          }
          su[st.k] = v; stepI++; setupScreen();
        };
      });
      if (h('#tn')) h('#tn').onclick = function () { stepI++; setupScreen(); };
    }
  }

  function intro() {
    var lines = ['Тебе ' + su.age + '.'];
    lines.push('Сегодня вечером ты ляжешь спать, как обычно. А проснёшься — в восемнадцать.');
    lines.push('Первый курс. Общежитие. Родители живы. Девушки ещё нет. Друзья — ещё не друзья, а просто люди, с которыми ты только знакомишься.');
    lines.push('Ты будешь помнить всё. Каждую ошибку. Каждое «если бы».');
    lines.push('Один ход — один месяц жизни. Когда жизнь яркая, событий в месяце будет много. Когда серая — месяцы и даже годы будут пролетать незаметно. Как в жизни.');
    app.innerHTML = '<div class="setup intro">' + lines.map(function (l) { return '<p>' + esc(l) + '</p>'; }).join('') +
      '<button class="btn primary" id="go">Закрыть глаза</button></div>';
    scrollTop();
    h('#go').onclick = function () {
      if (su.job === 'other') su.job = null;
      S = Z.newLife(su); S.tempo = su.tempo || 'normal';
      app.innerHTML = '<div class="fade-black"></div>';
      setTimeout(function () { Z.newTurn(S); save(); view = 'life'; render(); }, 1200);
    };
  }

  // ---------- Основной экран ----------
  function bar(k, icon, v) {
    return '<div class="stat" title="' + Z.STAT_N[k] + '"><span>' + icon + '</span><b><i style="width:' + Math.round(v) + '%"></i></b></div>';
  }
  function header() {
    var c = Z.cal(S);
    return '<header class="top">' +
      '<div class="when"><b>' + Z.cap(Z.MONTHS[c.mon]) + ' ' + c.year + '</b><span>' + Z.ageInt(S) + ' ' + Z.plural(Z.ageInt(S), 'год', 'года', 'лет') + (Z.gray(S) ? ' · <em>серый период</em>' : '') + '</span></div>' +
      '<button class="icon" id="menu">☰</button></header>' +
      '<div class="stats">' + bar('hp', '❤️‍🩹', S.st.hp) + bar('joy', '☀️', S.st.joy) + bar('money', '💰', S.st.money) + bar('sk', '🎓', S.st.sk) + '</div>' +
      '<button class="focus" id="focus">Фокус: ' + S.focus.map(function (k) { return Z.FOCUS[k].i + ' ' + Z.FOCUS[k].n; }).join(' · ') + ' <u>изменить</u></button>';
  }
  function nav() {
    var tabs = [['life', 'Жизнь'], ['people', 'Люди'], ['log', 'Летопись']];
    return '<nav class="tabs">' + tabs.map(function (t) { return '<button data-v="' + t[0] + '" class="' + (view === t[0] ? 'on' : '') + '">' + t[1] + '</button>'; }).join('') + '</nav>';
  }

  function render() {
    if (!S) return title();
    if (S.over) return endScreen();
    var body = view === 'people' ? peopleView() : view === 'log' ? logView() : lifeView();
    app.innerHTML = header() + '<main>' + body + '</main>' + nav();
    h('#menu').onclick = menu;
    h('#focus').onclick = focusPicker;
    app.querySelectorAll('.tabs button').forEach(function (b) { b.onclick = function () { view = b.dataset.v; render(); scrollTop(); }; });
    if (view === 'life') bindLife();
  }

  function lifeView() {
    var t = S.turn;
    if (!t) { Z.newTurn(S); t = S.turn; save(); }
    var html = '';
    t.notes.forEach(function (n) {
      if (typeof n === 'string') html += '<div class="note">' + esc(n) + '</div>';
      else html += '<div class="note gray">' + esc(n.t) + '</div>';
    });
    // уже прожитые карточки этого хода — свернуты
    for (var i = 0; i < t.i; i++) {
      var d = t.q[i]; if (!d.done) continue;
      html += '<div class="past"><b>' + esc(Z.t(Z.EV[d.id].title || '', S, d.ctx)) + '</b> — ' + esc(d.done.res.split('\n')[0]) + '</div>';
    }
    var inst = t.q[t.i];
    if (!inst) {
      html += '<div class="card calm"><p>Месяц прошёл спокойно.</p></div>';
      html += '<button class="btn primary next" id="next">Следующий месяц →</button>';
      return html;
    }
    var e = Z.EV[inst.id], ctx = inst.ctx || {};
    html += '<article class="card">' + (e.title ? '<h3>' + esc(Z.t(e.title, S, ctx)) + '</h3>' : '') + paras(Z.t(e.text, S, ctx));
    if (!inst.done) {
      if (e.ask) {
        var a = e.ask(S, ctx); inst.ph = inst.ph || a.ph;
        html += '<label class="ask">' + esc(a.label) + '<input class="inp" id="askv" maxlength="20" placeholder="' + esc(inst.ph) + '"></label>';
      }
      html += '<div class="choices">' + Z.choicesOf(S, e, ctx).map(function (c, i) {
        return '<button class="choice" data-i="' + i + '">' + esc(Z.t(c.t, S, ctx)) + '</button>';
      }).join('') + '</div>';
    } else {
      html += '<div class="result">' + paras(inst.done.res) + '</div>';
      if (inst.done.d.length) html += '<div class="deltas">' + inst.done.d.map(function (x) {
        return '<span class="' + (x.d > 0 ? 'up' : 'down') + '">' + (x.rel ? '♥ ' : '') + esc(x.n) + ' ' + (x.d > 0 ? '+' : '−') + Math.abs(x.d) + '</span>';
      }).join('') + '</div>';
      var more = t.i + 1 < t.q.length;
      html += '<button class="btn primary next" id="next">' + (S.over ? 'Итоги жизни' : more ? 'Дальше' : 'Следующий месяц →') + '</button>';
    }
    html += '</article>';
    return html;
  }

  function bindLife() {
    app.querySelectorAll('.choice').forEach(function (b) {
      b.onclick = function () {
        var t = S.turn, inst = t.q[t.i];
        var inp = h('#askv'); var val = inp ? (inp.value.trim() || inst.ph) : null;
        Z.apply(S, +b.dataset.i, val);
        save(); render();
        var r = h('.result'); if (r) r.scrollIntoView({ behavior: 'smooth', block: 'center' });
      };
    });
    var nx = h('#next');
    if (nx) nx.onclick = function () {
      var t = S.turn;
      if (S.over) { save(); return render(); }
      if (!(t.q[t.i] && Z.next(S))) Z.newTurn(S);
      save(); render(); scrollTop();
    };
  }

  // ---------- Люди ----------
  function heart(r) { return '<b class="rel"><i style="width:' + Math.round(r) + '%"></i></b>'; }
  function personRow(p, sub) {
    return '<li><div><b>' + esc(Z.cap(p.n)) + '</b><small>' + esc(sub || '') + '</small></div>' + (p.alive && !p.gone ? heart(p.rel) : '<span class="gone">' + (p.gone ? 'потерялись' : 'нет с нами') + '</span>') + '</li>';
  }
  function peopleView() {
    var s = S, html = '<section class="ppl">';
    html += '<h4>Семья</h4><ul>';
    var P = Z.P(s);
    if (P) html += personRow(P, (Z.married(s) ? 'жена, ' + Z.yearsStr(Math.floor(Z.yearsMarried(s))) + ' в браке' : 'вместе ' + Z.yearsStr(Math.floor(Z.yearsTogether(s)))) + ' · ' + Z.PARTNERS[P.id].desc);
    s.kids.forEach(function (id) { var k = s.pp[id]; html += personRow(k, (k.fem ? 'дочь' : 'сын') + ', ' + Z.yearsStr(Math.max(0, Math.floor(Z.kidAge(s, k))))); });
    html += personRow(s.pp.mom, 'мама') + personRow(s.pp.dad, 'папа') + '</ul>';
    var fr = Object.keys(Z.FRIENDS).filter(function (id) { return s.pp[id].met; });
    if (fr.length) {
      html += '<h4>Друзья</h4><ul>' + fr.sort(function (a, b) { return s.pp[b].rel - s.pp[a].rel; }).map(function (id) {
        return personRow(s.pp[id], (Z.isClose(s, id) ? '★ близкий друг · ' : '') + Z.FRIENDS[id].desc);
      }).join('') + '</ul>';
    }
    var ws = Object.keys(Z.PARTNERS).filter(function (id) { return s.pp[id].met && id !== s.partner; });
    if (ws.length) html += '<h4>Они</h4><ul>' + ws.map(function (id) { var p = s.pp[id]; return personRow(p, (s.exes.indexOf(id) >= 0 ? 'бывшая · ' : s.f['taken_' + id] ? 'замужем · ' : '') + Z.PARTNERS[id].desc); }).join('') + '</ul>';
    html += '<h4>Дело</h4><ul><li><div><b>' + (s.student ? 'Студент' : s.job ? Z.cap(Z.jobTitle(s)) : 'Без работы') + '</b><small>' +
      (s.edu ? Z.EDU[s.edu].n + ' факультет' + (s.degree ? ', диплом' : s.f.dropout ? ', без диплома' : '') : '') +
      (s.job && !s.student ? ' · ' + (s.fit[s.job] >= 30 ? 'любимая работа' : s.fit[s.job] >= 15 ? 'нравится' : 'просто работа') : '') + '</small></div></li></ul>';
    var R = s.setup.regrets || {};
    if (Object.keys(R).length) html += '<h4>Что я хочу изменить</h4><ul class="goals">' + Object.keys(R).map(function (k) { return '<li>' + esc(Z.REGRETS[k]) + '</li>'; }).join('') + '</ul>';
    return html + '</section>';
  }

  // ---------- Летопись ----------
  function logView() {
    if (!S.log.length) return '<p class="empty">Здесь появятся главные события твоей жизни.</p>';
    var byYear = {}, years = [];
    S.log.forEach(function (l) { var y = Z.cal(S, l.m).year; if (!byYear[y]) { byYear[y] = []; years.push(y); } byYear[y].push(l); });
    return '<section class="log">' + years.reverse().map(function (y) {
      var age = y - S.y0 + 18;
      return '<h4>' + y + ' <small>' + age + ' ' + Z.plural(age, 'год', 'года', 'лет') + '</small></h4><ul>' + byYear[y].map(function (l) { return '<li class="' + l.k + '">' + esc(l.t) + '</li>'; }).join('') + '</ul>';
    }).join('') + '</section>';
  }

  // ---------- Фокус ----------
  function focusPicker() {
    var sel = S.focus.slice();
    var draw = function () {
      var html = '<div class="modal"><div class="sheet"><h3>На что ты тратишь силы?</h3><p class="hint">Выбери два направления. От них зависит, что будет расти, а что — угасать.</p><div class="opts">' +
        Object.keys(Z.FOCUS).map(function (k) { return '<button class="opt' + (sel.indexOf(k) >= 0 ? ' on' : '') + '" data-k="' + k + '">' + Z.FOCUS[k].i + ' ' + Z.FOCUS[k].n + '</button>'; }).join('') +
        '</div><button class="btn primary" id="fok"' + (sel.length === 2 ? '' : ' disabled') + '>Готово</button></div></div>';
      var m = document.createElement('div'); m.innerHTML = html; var old = document.querySelector('.modal'); if (old) old.remove();
      document.body.appendChild(m.firstChild);
      document.querySelectorAll('.modal .opt').forEach(function (b) {
        b.onclick = function () { var k = b.dataset.k, i = sel.indexOf(k); if (i >= 0) sel.splice(i, 1); else { if (sel.length >= 2) sel.shift(); sel.push(k); } draw(); };
      });
      document.querySelector('#fok').onclick = function () { if (sel.length !== 2) return; S.focus = sel; save(); document.querySelector('.modal').remove(); render(); };
      document.querySelector('.modal').onclick = function (e) { if (e.target.classList.contains('modal')) e.target.remove(); };
    };
    draw();
  }

  // ---------- Меню ----------
  function menu() {
    var html = '<div class="modal"><div class="sheet"><h3>Меню</h3>' +
      '<p class="hint">Темп жизни</p><div class="opts">' + [['slow', 'Подробно'], ['normal', 'Обычно'], ['fast', 'Быстро']].map(function (o) { return '<button class="opt' + (S.tempo === o[0] ? ' on' : '') + '" data-t="' + o[0] + '">' + o[1] + '</button>'; }).join('') + '</div>' +
      '<button class="btn" id="home">На главный экран</button>' +
      '<button class="btn danger" id="reset">Начать жизнь заново</button>' +
      '<p class="fine">Версия ' + Z.VERSION + '. Прогресс сохраняется на этом устройстве.</p></div></div>';
    var m = document.createElement('div'); m.innerHTML = html; document.body.appendChild(m.firstChild);
    var md = document.querySelector('.modal');
    md.onclick = function (e) { if (e.target === md) md.remove(); };
    md.querySelectorAll('[data-t]').forEach(function (b) { b.onclick = function () { S.tempo = b.dataset.t; save(); md.remove(); }; });
    md.querySelector('#home').onclick = function () { md.remove(); title(); };
    md.querySelector('#reset').onclick = function () { if (confirm('Стереть эту жизнь и начать новую?')) { clearSave(); S = null; md.remove(); su = { regrets: {} }; stepI = 0; setupScreen(); } };
  }

  // ---------- Итоги ----------
  function endScreen() {
    var E = Z.ending(S);
    var html = '<div class="ending' + (E.death ? ' death' : '') + '"><p class="kicker">' + (E.death ? 'Итог' : 'Итог жизни · ' + E.age + ' ' + Z.plural(E.age, 'год', 'года', 'лет')) + '</p><h1>' + esc(E.title) + '</h1>' +
      E.paragraphs.map(function (p) { return '<p>' + esc(p) + '</p>'; }).join('');
    if (E.goals.length) html += '<h4>Что ты хотел изменить · ' + E.fixed + ' из ' + E.goals.length + '</h4><ul class="goals res">' + E.goals.map(function (g) { return '<li class="' + (g.ok ? 'ok' : 'no') + '"><b>' + (g.ok ? '✓ ' : '○ ') + esc(g.n) + '</b><span>' + esc(g.t) + '</span></li>'; }).join('') + '</ul>';
    html += '<h4>Тогда и сейчас</h4><table class="cmp"><tr><th></th><th>Прошлая жизнь</th><th>Новая жизнь</th></tr>' + E.compare.map(function (r) { return '<tr><td>' + esc(r[0]) + '</td><td>' + esc(r[1]) + '</td><td>' + esc(r[2]) + '</td></tr>'; }).join('') + '</table>';
    html += '<h4>Что взять с собой в настоящую жизнь</h4><ul class="refl">' + E.refl.map(function (r) { return '<li>' + esc(r) + '</li>'; }).join('') + '</ul>';
    html += '<button class="btn" id="chron">Летопись этой жизни</button><button class="btn primary" id="again">Прожить ещё раз</button></div>';
    app.innerHTML = html; scrollTop();
    h('#again').onclick = function () { clearSave(); S = null; su = { regrets: {} }; stepI = 0; setupScreen(); };
    h('#chron').onclick = function () { var box = document.createElement('div'); box.innerHTML = '<div class="modal"><div class="sheet tall">' + logView() + '<button class="btn" id="cl">Закрыть</button></div></div>'; document.body.appendChild(box.firstChild); document.querySelector('#cl').onclick = function () { document.querySelector('.modal').remove(); }; };
  }

  Z.boot = function () {
    app = document.getElementById('app');
    title();
  };
})();
