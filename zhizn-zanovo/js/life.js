// Механики жизни: отношения, дети, работа, утраты, близкие друзья.
(function () {
  'use strict';
  var Z = window.Z;
  var R = Z.R, clamp = Z.clamp;

  // ---------- Любовь ----------
  Z.startDating = function (s, id) {
    if (s.partner && s.partner !== id) Z.breakUp(s, true);
    s.partner = id; s.pst = 'dating'; s.pSince = s.m; s.pMonths = 0;
    Z.meet(s, id); var p = s.pp[id]; p.rel = Math.max(p.rel, 50);
    delete s.f['ex_' + id];
    Z.logLine(s, 'Вы с ' + p.forms.i + ' — вместе.', 'love');
  };
  Z.breakUp = function (s, quiet) {
    var id = s.partner; if (!id) return;
    var p = s.pp[id], wasMarried = s.pst === 'married';
    s.exes.push(id); s.f['ex_' + id] = s.m;
    s.partner = null; s.pst = null; s.pMonths = 0;
    delete s.f.affair; delete s.f.p_home; delete s.f.livetogether;
    p.rel = Math.min(p.rel, 25);
    if (wasMarried) {
      s.f.divorced = true; s.cnt.divorce = (s.cnt.divorce || 0) + 1;
      Z.kids(s).forEach(function (k) { k.rel = clamp(k.rel - 10, 0, 100); });
      Z.logLine(s, 'Развод с ' + p.forms.i + '.', 'love');
      s.st.joy = clamp(s.st.joy - 15, 0, 100);
    } else if (!quiet) {
      Z.logLine(s, 'Вы с ' + p.forms.i + ' расстались.', 'love');
      s.st.joy = clamp(s.st.joy - 8, 0, 100);
    }
  };
  Z.marry = function (s) {
    s.pst = 'married'; s.wedM = s.m; s.cnt.married = (s.cnt.married || 0) + 1;
    Z.logLine(s, 'Свадьба с ' + s.pp[s.partner].forms.i + '.', 'love');
  };
  Z.yearsTogether = function (s) { return s.partner ? (s.m - s.pSince) / 12 : 0; };
  Z.yearsMarried = function (s) { return Z.married(s) ? (s.m - s.wedM) / 12 : 0; };
  // Может ли с ней ещё что-то начаться
  Z.canDate = function (s, id) {
    var p = s.pp[id], d = Z.PARTNERS[id], a = Z.age(s);
    if (!p.alive || s.partner === id) return false;
    if (s.f['ex_' + id] != null && s.m - s.f['ex_' + id] < 36) return false;
    if (s.f['late_' + id]) return true;
    if (s.f['taken_' + id]) return false;
    if (s.f['ex_' + id] != null && s.m - s.f['ex_' + id] < 36) return false;
    return a >= d.from && a < d.until;
  };

  // ---------- Дети ----------
  Z.KID_NAMES_M = ['Миша', 'Ваня', 'Саша', 'Максим', 'Артём', 'Даня', 'Илья', 'Костя'];
  Z.KID_NAMES_F = ['Маша', 'Соня', 'Аня', 'Даша', 'Катя', 'Варя', 'Алиса', 'Вера'];
  Z.birth = function (s, name, fem) {
    var id = 'k' + (s.kids.length + 1);
    var p = Z.addPerson(s, id, { n: name, fem: fem, kind: 'kid', rel: 70, met: true });
    p.born = s.m; p.mother = s.partner;
    s.kids.push(id);
    Z.logLine(s, 'Родил' + (fem ? 'ась дочь' : 'ся сын') + ' — ' + name + '.', 'kid');
    s.st.joy = clamp(s.st.joy + 15, 0, 100);
    return p;
  };
  Z.kidsAged = function (s, a, b) {
    return Z.kids(s).filter(function (k) { var x = Z.kidAge(s, k); return x >= a && x < b; }).map(function (k) { return { K: k.id }; });
  };

  // ---------- Работа ----------
  Z.JOB_I = { prog: 'программистом', eng: 'инженером', arch: 'архитектором', design: 'дизайнером', doctor: 'врачом', psych: 'психологом',
    teacher: 'учителем', journ: 'журналистом', writer: 'писателем', lawyer: 'юристом', account: 'финансистом', sales: 'менеджером по продажам',
    marketing: 'маркетологом', biz: 'предпринимателем', science: 'учёным', music: 'музыкантом', cook: 'поваром', photo: 'фотографом',
    rescue: 'спасателем', builder: 'прорабом' };
  Z.jobOpen = function (s, id) {
    var J = Z.JOBS[id];
    if (id === 'biz') return false; // только через своё дело
    if (id === 'rescue' && s.st.hp < 60) return false;
    if (id === 'science') return !!s.f.grad;
    if (J.edu.length && s.degree && J.edu.indexOf(s.edu) >= 0) return true;
    if (J.fit && (s.fit[id] || 0) >= J.fit) return true;
    if (!J.edu.length && !J.fit) return true;
    return false;
  };
  Z.openJobs = function (s) {
    return Object.keys(Z.JOBS).filter(function (id) { return id !== s.job && Z.jobOpen(s, id); });
  };
  Z.setJob = function (s, id, lvl) {
    if (s.job && s.job !== id) s.jobsHad.push(s.job);
    s.job = id; s.lvl = lvl || 0; s.jobM = 0; s.lvlM = 0;
    if (Z.age(s) > 22.5) s.student = false;
    Z.logLine(s, 'Новая работа: ' + Z.JOBS[id].t[s.lvl] + '.', 'work');
  };
  Z.quitJob = function (s, why) {
    if (!s.job) return;
    s.jobsHad.push(s.job);
    Z.logLine(s, (why || 'Ты ушёл с работы') + ' (' + Z.JOBS[s.job].n + ').', 'work');
    s.job = null; s.lvl = 0; s.jobM = 0; s.lvlM = 0;
  };
  Z.promote = function (s) {
    if (!s.job || s.lvl >= 3) return;
    s.lvl++; s.lvlM = 0;
    Z.logLine(s, 'Повышение: ' + Z.JOBS[s.job].t[s.lvl] + '.', 'work');
  };
  Z.canPromote = function (s) {
    if (!s.job || s.lvl >= 3 || s.student) return false;
    var need = [0, 30, 50, 70][s.lvl + 1];
    return s.st.sk >= need && s.lvlM >= 18;
  };
  // Предложения о работе: до трёх, лучше подходящие — чаще
  Z.offerJobs = function (s, n) {
    var list = Z.openJobs(s);
    list = R.shuffle(list).sort(function (a, b) { return (s.fit[b] || 0) - (s.fit[a] || 0) + (R.rnd() - 0.5) * 30; });
    return list.slice(0, n || 3);
  };
  Z.jobChoices = function (s, opts) {
    opts = opts || {};
    var list = (opts.ids || Z.offerJobs(s, opts.n || 3)).map(function (id) {
      var J = Z.JOBS[id], past = s.setup.job === id;
      var lvl = opts.lvl != null ? opts.lvl : (s.st.sk >= 55 && Z.age(s) > 28 ? 1 : 0);
      if (J.fit && !(J.edu.length && J.edu.indexOf(s.edu) >= 0 && s.degree)) lvl = Math.min(lvl, 1);
      return {
        t: Z.cap(J.t[lvl]) + (past ? ' (знакомая дорога)' : ''),
        run: function (st) {
          Z.setJob(st, id, lvl);
          var fitTxt = (st.fit[id] || 0) >= 25 ? ' С первых дней чувствуешь: это — твоё.' : '';
          var pastTxt = past ? ' Ты уже был ' + Z.JOB_I[id] + ' в прошлой жизни — руки помнят, но смотришь ты теперь иначе.' : '';
          st.st.joy = clamp(st.st.joy + 6, 0, 100);
          return 'Ты выходишь на новое место: ' + J.t[lvl] + '.' + pastTxt + fitTxt;
        }
      };
    });
    return list;
  };

  // ---------- Утраты ----------
  Z.die = function (s, id, text) {
    var p = s.pp[id]; if (!p || !p.alive) return;
    p.alive = false; p.diedM = s.m;
    var deep = p.kind === 'parent' || p.kind === 'kid' || id === s.partner || Z.isClose(s, id);
    if (deep) s.grief = 12;
    if (id === s.partner) { s.partner = null; s.pst = null; s.f.widower = true; }
    s.close = s.close.filter(function (x) { return x !== id; });
    Z.logLine(s, text || ('Не стало ' + p.forms.g + '.'), 'loss');
    s.st.joy = clamp(s.st.joy - (deep ? 20 : 10), 0, 100);
  };

  Z.lose = function (s, id, text) {
    var p = s.pp[id]; if (!p) return;
    p.gone = true; p.rel = 0;
    s.close = s.close.filter(function (x) { return x !== id; });
    Z.logLine(s, text || ('Вы потеряли связь с ' + p.forms.i + '.'), 'loss');
  };

  // ---------- Близкие друзья ----------
  Z.pickClose = function (s) {
    var fr = Z.friendIds(s).sort(function (a, b) { return s.pp[b].rel - s.pp[a].rel; }).filter(function (id) { return s.pp[id].rel >= 35; });
    s.close = fr.slice(0, 2);
    return s.close;
  };

  // ---------- Помощники для условий ----------
  Z.metFriends = function (s, filter) {
    return Z.friendIds(s).filter(function (id) { return !filter || filter(s.pp[id], id); }).map(function (id) { return { F: id }; });
  };
  Z.has = function (s, k) { return s.focus.indexOf(k) >= 0; };
  Z.riskFriend = function (s, id) { return s.risk.friend && s.risk.friend.id === id; };
  Z.fem = function (s, id) { return s.pp[id] && s.pp[id].fem; };
})();
