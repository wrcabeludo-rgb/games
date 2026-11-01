// Работа: 20 профессий, повышения, выгорание, своё дело, смена профессии.
(function () {
  'use strict';
  var Z = window.Z, R = Z.R;
  var A = Z.age;
  var working = function (s) { return Z.working(s); };
  var hbJob = function (s) { return ['writer', 'music', 'photo', 'design'].filter(function (x) { return (s.fit[x] || 0) >= Z.JOBS[x].fit && s.job !== x; })[0] || 'writer'; };

  Z.def([
    {
      id: 'w_offer', manual: true, title: 'Предложения',
      text: function (s) {
        var t = 'Ты рассылаешь резюме, ходишь на собеседования. Есть несколько вариантов.';
        if (s.setup.job && Z.jobOpen(s, s.setup.job) && s.job !== s.setup.job) t += ' Среди них — работа, которой ты занимался всю прошлую жизнь. ' + (s.setup.regrets.calling ? 'Ты помнишь, как она тебя съедала.' : 'Ты знаешь её до мелочей.');
        return t;
      },
      choices: function (s) {
        var ids = Z.offerJobs(s, 3), past = s.setup.job;
        if (past && Z.jobOpen(s, past) && s.job !== past && ids.indexOf(past) < 0) ids = ids.slice(0, 2).concat([past]);
        var list = Z.jobChoices(s, { ids: ids });
        list.push({ t: 'Подождать чего-то получше', fx: 'joy-2', run: function (st) { Z.schedule(st, 'w_offer', R.int(2, 4)); }, res: 'Ты отказываешь всем. Рискованно. Но ты уже знаешь цену работе, которую не любишь.' });
        return list;
      }
    },
    {
      id: 'w_unemployed', prio: 3, rep: 5, if: function (s) { return !s.job && !s.student && A(s) > 22 && A(s) < 63 && !s.queue.some(function (q) { return q.id === 'w_offer'; }); }, title: 'Без работы',
      text: 'Деньги тают. Утром некуда идти. Мама по телефону осторожно спрашивает «ну как, нашёл что-нибудь?».',
      choices: [
        { t: 'Искать всерьёз', fx: 'joy-2', run: function (s) { Z.chain(s, 'w_offer'); }, res: 'Ты садишься за объявления.' },
        { t: 'Взять что угодно, лишь бы платили', run: function (s) { Z.setJob(s, R.pick(['sales', 'cook', 'builder'].filter(function (j) { return Z.jobOpen(s, j); }).concat(['sales'])), 0); s.st.joy -= 3; return 'Работа не мечты. Но с утра снова есть куда идти.'; } },
        { t: 'Взять паузу — понять, чего хочешь на самом деле', if: function (s) { return s.st.money > 25; }, fx: 'joy+4 money-6', run: function (s) { Object.keys(Z.HOBBY).forEach(function (h) { if (s.f['h_' + h]) Z.fx(s, 'hobby.' + h + '+10'); }); Z.schedule(s, 'w_offer', 3); }, res: 'Три месяца ты читаешь, гуляешь, пробуешь. И кое-что про себя понимаешь.' }
      ]
    },
    {
      id: 'w_first_day', per: 'J', ctx: function (s) { return s.job ? { J: s.job } : null; }, w: 40, if: function (s) { return working(s) && s.jobM < 4; }, title: 'Новенький',
      text: function (s) { return 'Новое место: ' + Z.jobTitle(s) + '. Коллеги присматриваются. В курилке тебя рассматривает ироничный парень: «Новенький? Я Лёха. Совет: никогда не соглашайся на первое задание шефа после обеда».'; },
      choices: [
        { t: 'Посмеяться и подружиться', fx: 'met:lyokha @lyokha+12 joy+3', res: 'С Лёхой работать веселее. Он знает всё про всех и ничего не принимает всерьёз.' },
        { t: 'С головой в работу', fx: 'met:lyokha sk+4', res: 'Ты остаёшься допоздна. Начальник замечает.' }
      ]
    },
    {
      id: 'w_promo', rep: 6, w: 22, if: function (s) { return Z.canPromote(s) && s.job !== 'biz'; }, title: 'Повышение',
      text: function (s) { return 'Начальство предлагает повышение: ' + Z.JOBS[s.job].t[s.lvl + 1] + '. Больше денег, больше ответственности — и меньше вечеров дома.'; },
      choices: [
        { t: 'Согласиться', fx: 'joy+6', run: function (s) { Z.promote(s); }, res: 'Новый кабинет, новые обязанности. Ты помнишь, как в прошлой жизни мечтал об этом. Теперь посмотрим, стоило ли.' },
        { t: 'Отказаться — мне хорошо там, где я есть', fx: 'joy+2', run: function (s) { s.lvlM = 0; }, res: 'Начальник удивлён. Ты — нет. Ты знаешь, сколько стоят вечера.' }
      ]
    },
    {
      id: 'w_daily', per: 'J', rep: 14, w: 8, ctx: function (s) { return s.job && working(s) ? { J: s.job } : null; }, if: function (s, c) { return s.job === c.J; }, title: 'Хороший день',
      text: function (s, c) { return Z.JOBS[c.J].good; },
      choices: [
        { t: 'Запомнить этот день', fx: 'joy+5 sk+1', run: function (s) { s.fit[s.job] = (s.fit[s.job] || 0) + 3; }, res: 'Такие дни — ради них всё и затевалось.' },
        { t: 'Отметить с коллегами', fx: 'joy+4 @lyokha+3', res: 'Вы празднуете в кафе за углом. Лёха произносит издевательски-трогательный тост.' }
      ]
    },
    {
      id: 'w_dilemma', per: 'J', w: 14, ctx: function (s) { return s.job && working(s) && s.jobM > 6 ? { J: s.job } : null; }, if: function (s, c) { return s.job === c.J; }, title: 'Выбор',
      text: function (s, c) { return Z.JOBS[c.J].dl.q; },
      choices: function (s, c) {
        var d = Z.JOBS[c.J].dl;
        return [{ t: d.a[0], fx: d.a[1], res: d.a[2] }, { t: d.b[0], fx: d.b[1], res: d.b[2] }];
      }
    },
    {
      id: 'w_overtime', rep: 10, w: 9, if: function (s) { return working(s); }, title: 'Выходные',
      text: function (s) { return 'Пятница, шесть вечера. Начальник: «Надо выйти в субботу и воскресенье. Аврал».' + (Z.married(s) ? ' А ты обещал {P.d} поехать за город.' : '') + (s.setup.why === 'work' && s.f.pastwife === s.partner ? ' Ты помнишь, сколько таких суббот стоил тебе прошлый брак.' : ''); },
      choices: [
        { t: 'Выйти — карьера важна', fx: 'sk+3 money+3 @P-6 @kids-3 joy-2', run: function (s) { s.cnt.overtime = (s.cnt.overtime || 0) + 1; }, res: 'Выходные в офисе. Аврал закрыт. Дома тебя встречает тишина.' },
        { t: 'Отказаться: «У меня планы с семьёй»', fx: '@P+5 @kids+3 joy+3', run: function (s) { if (R.chance(0.15)) { s.lvlM = Math.max(0, s.lvlM - 6); return 'Начальник поджимает губы. Это запомнят. Но выходные — твои.'; } }, res: 'Начальник ворчит, но отпускает. Мир не рухнул.' },
        { t: 'Выйти на один день', fx: 'sk+1 money+1 @P-2', res: 'Компромисс. Никто не доволен, все живы.' }
      ]
    },
    {
      id: 'w_boss', rep: 40, w: 6, if: function (s) { return working(s) && s.lvl < 3 && s.job !== 'biz'; }, title: 'Начальник',
      text: 'Новый начальник унижает людей на планёрках. Сегодня — тебя, при всех, за чужую ошибку.',
      choices: [
        { t: 'Спокойно, но твёрдо ответить при всех', fx: 'joy+3 +brave', run: function (s) { if (R.chance(0.3)) { Z.quitJob(s, 'Уволили после стычки с начальником'); Z.schedule(s, 'w_offer', 1); return 'Тебя увольняют через неделю. Коллеги провожают тебя как героя. Обидно — и почему-то легко.'; } }, res: 'Тишина в переговорной. Начальник краснеет. Больше он тебя не трогает. А коллеги смотрят иначе.' },
        { t: 'Стерпеть', fx: 'joy-5', res: 'Ты молчишь. Вечером срываешься на близких.' },
        { t: 'Уволиться — жизнь одна. Ну, две', run: function (s) { Z.quitJob(s, 'Ушёл от плохого начальника'); Z.schedule(s, 'w_offer', 1); s.st.joy += 4; return 'Ты кладёшь заявление на стол. Начальник не верит. Ты выходишь на улицу, и воздух кажется вкуснее.'; } }
      ]
    },
    {
      id: 'w_burnout', prio: 3, rep: 36, if: function (s) { return working(s) && s.st.joy < 38 && (s.cnt.overtime || 0) >= 3 && Z.has(s, 'work'); }, title: 'Выгорание',
      text: 'Ты сидишь в машине у офиса и не можешь заставить себя выйти. Двадцать минут. Сердце колотится без причины. Ты знаешь это состояние — в прошлой жизни оно длилось годами.',
      choices: [
        { t: 'Взять отпуск и уехать туда, где нет связи', fx: 'joy+10 hp+5 money-4', run: function (s) { s.cnt.overtime = 0; }, res: 'Две недели в горах. Первые три дня ты спишь. Потом — снова видишь небо.' },
        { t: 'Пойти к психологу', fx: 'joy+8 money-3 +therapy', run: function (s) { s.cnt.overtime = 0; }, res: 'Оказывается, это не слабость. Это сигнал. Ты учишься его слышать.' },
        { t: 'Сменить приоритеты: меньше работы, больше жизни', fx: 'joy+6', run: function (s) { s.cnt.overtime = 0; s.focus = ['health', 'love']; }, res: 'Ты уходишь вовремя. Каждый день. И мир не рушится.' },
        { t: 'Терпеть', fx: 'hp-6 joy-4', res: 'Ты выходишь из машины. Ещё один день.' }
      ]
    },
    {
      id: 'w_headhunt', rep: 48, w: 6, if: function (s) { return working(s) && s.st.sk > 45 && s.job !== 'biz'; }, title: 'Предложение',
      text: function (s) { return 'Звонок от конкурентов: тебя хотят переманить. Должность выше, денег вдвое больше. Но — в другом городе.' + (Z.parentsAlive(s).length ? ' А родители стареют.' : ''); },
      choices: [
        { t: 'Ехать — рискнуть', fx: '+brave money+10 @parents-6 @friends-6 joy+4', run: function (s) { s.lvl = Math.min(3, s.lvl + 1); s.lvlM = 0; delete s.f.hometown; s.f.moved = true; Z.logLine(s, 'Переехал в другой город ради работы.', 'work'); }, res: 'Новый город, новый офис. Первые месяцы — одиночество и азарт.' },
        { t: 'Остаться', fx: 'joy+1', res: 'Ты остаёшься. Деньги — не всё. Хотя иногда ты думаешь о том звонке.' },
        { t: 'Использовать как повод поговорить о повышении здесь', fx: 'money+4', run: function (s) { if (s.lvl < 3 && R.chance(0.5)) Z.promote(s); }, res: 'Начальник неожиданно сговорчив.' }
      ]
    },
    {
      id: 'w_layoff', rep: 72, w: 3, if: function (s) { return working(s) && s.job !== 'biz' && A(s) > 25; }, title: 'Сокращение',
      text: 'Кризис. В отделе кадров пахнет валерьянкой. Тебя вызывают последним: «Мы вынуждены…»',
      choices: [
        { t: 'Принять и искать новое', run: function (s) { Z.quitJob(s, 'Попал под сокращение'); Z.schedule(s, 'w_offer', 1); s.st.joy -= 6; return 'Коробка с вещами. Кактус с подоконника. Новая страница.'; } },
        { t: 'Использовать шанс — заняться тем, о чём мечтал', run: function (s) { Z.quitJob(s, 'Попал под сокращение'); Z.chain(s, 'w_retrain'); return 'Ты выходишь на улицу и вдруг смеёшься: тебя только что освободили.'; } }
      ]
    },
    {
      id: 'w_retrain', rep: 60, w: 7, age: [27, 58], if: function (s) { return !s.f.retraining && (!s.job || (s.fit[s.job] || 0) < 20); }, title: 'Ещё не поздно',
      text: function (s) { return 'Ты ловишь себя на том, что ненавидишь понедельники. ' + (A(s) > 40 ? 'Тебе ' + Z.ageInt(s) + '. «Поздно», — говорит голос в голове. «Тебе было ' + s.setup.age + ', когда ты получил второй шанс», — отвечает другой.' : 'Может, пора заняться тем, что действительно твоё?'); },
      choices: function (s) {
        var best = Object.keys(Z.JOBS).filter(function (j) { return j !== 'biz' && j !== s.job; }).sort(function (a, b) { return (s.fit[b] || 0) - (s.fit[a] || 0); }).slice(0, 3);
        var list = best.map(function (j) {
          return { t: 'Переучиться: ' + Z.JOBS[j].n, run: function (st) { st.f.retraining = j; Z.fx(st, 'money-10 joy+6 +brave'); st.fit[j] = (st.fit[j] || 0) + 15; Z.schedule(st, 'w_retrain_done', 10); Z.logLine(st, 'Начал переучиваться: ' + Z.JOBS[j].n + '.', 'work'); return 'Вечерние курсы, книги, практика. Ты самый старший в группе — и самый жадный до знаний.'; } };
        });
        list.push({ t: 'Не сейчас', fx: 'joy-2', res: 'Понедельники продолжаются.' });
        return list;
      }
    },
    {
      id: 'w_retrain_done', manual: true, title: 'Новая профессия',
      text: function (s) { return 'Курсы позади. Диплом, портфолио, первые заказы. Ты — ' + Z.JOBS[s.f.retraining].n + '.'; },
      choices: [
        { t: 'Начать с нуля на новом месте', run: function (s) { var j = s.f.retraining; delete s.f.retraining; s.f['re_' + j] = true; if (s.job) Z.quitJob(s, 'Сменил профессию'); Z.setJob(s, j, 0); s.st.joy += 10; s.st.sk = Math.max(s.st.sk - 10, 25); return 'Ты снова новичок. В ' + Z.ageInt(s) + '. И тебе нравится каждый день.'; } }
      ]
    },
    {
      id: 'w_biz_result', manual: true, title: 'Три года спустя',
      text: 'Бизнес с Пашей. Момент истины.',
      choices: [
        { t: 'Посмотреть цифры', run: function (s) {
          var ok = R.chance(0.35 + s.st.sk / 250 + (s.fit.biz || 0) / 200);
          if (ok) {
            Z.fx(s, 'money+25 joy+12 @pasha+10');
            if (s.job === 'biz') { s.lvl = 2; s.lvlM = 0; }
            Z.logLine(s, 'Своё дело выстрелило.', 'work');
            return 'Получилось! Контракты, сотрудники, свой офис. Паша отплясывает на столе. Ты смотришь в окно и не веришь: ты сделал то, на что не решился в прошлой жизни.';
          }
          Z.fx(s, 'money-15 joy-10 +debt');
          Z.schedule(s, 'w_debt_clear', R.int(24, 40));
          if (s.job === 'biz') { Z.quitJob(s, 'Своё дело прогорело'); Z.schedule(s, 'w_offer', 1); }
          return 'Прогорели. Долги, пустой офис, Паша не смотрит в глаза. Больно. Но ты рискнул — и это у тебя никто не отнимет.';
        } }
      ]
    },
    {
      id: 'w_debt_clear', manual: true, title: 'Последний платёж',
      text: 'Ты вносишь последний платёж по долгам. Всё. Чисто.',
      choices: [{ t: 'Выдохнуть', fx: '-debt joy+8', res: 'Ты выходишь из банка и покупаешь себе мороженое. Как в детстве.' }]
    },
    {
      id: 'w_ownbiz_solo', age: [26, 55], w: 5, if: function (s) { return working(s) && !s.f.ownbiz && s.job !== 'biz' && s.lvl >= 1 && s.st.sk > 45; }, title: 'Сам себе хозяин',
      text: function (s) { return 'Ты знаешь своё дело лучше начальства. Клиенты спрашивают лично тебя. Может, открыть собственное — ' + (s.job === 'cook' ? 'ресторан' : s.job === 'doctor' ? 'частную клинику' : s.job === 'teacher' ? 'частную школу' : 'фирму') + '?'; },
      choices: [
        { t: 'Рискнуть', fx: '+brave +ownbiz money-12', run: function (s) { var j = s.job; s.f.ownjob = j; s.lvl = 3; s.lvlM = 0; Z.logLine(s, 'Открыл своё дело.', 'work'); Z.schedule(s, 'w_own_result', R.int(12, 24)); }, res: 'Вывеска с твоим именем. Первый клиент. Руки дрожат, когда отдаёшь ему сдачу.' },
        { t: 'Не сейчас', fx: '', res: 'Стабильность — тоже ценность.' }
      ]
    },
    {
      id: 'w_own_result', manual: true, title: 'Своё',
      text: 'Год работы на себя.',
      choices: [{ t: 'Подвести итоги', run: function (s) { if (R.chance(0.55 + s.st.sk / 300)) { Z.fx(s, 'money+20 joy+10'); return 'Дело живёт. Ты платишь людям зарплату и засыпаешь спокойно — ну, почти.'; } Z.fx(s, 'money-12 joy-8'); s.lvl = 1; return 'Тяжело. Пришлось закрыться и вернуться под чужую вывеску. Но опыт — твой.'; } }]
    },
    {
      id: 'w_hobby_break', age: [22, 65], w: 7, if: function (s) { return ['writer', 'music', 'photo', 'design'].some(function (j) { return (s.fit[j] || 0) >= Z.JOBS[j].fit && s.job !== j; }); }, title: 'Шанс',
      text: function (s) { var j = hbJob(s); return { writer: 'Твой рассказ, отправленный наугад в журнал, напечатали. Редактор пишет: «Есть ещё?»', music: 'Тебя слышат на квартирнике, и владелец клуба предлагает выступать каждую пятницу. За деньги.', photo: 'Твои снимки берут на выставку. Посетители подолгу стоят у каждого.', design: 'Твои рисунки замечает агентство: «Хотите работать у нас?»' }[j]; },
      choices: [
        { t: 'Сделать это своей работой', fx: '+brave', run: function (s) { var j = hbJob(s); if (s.job) Z.quitJob(s, 'Ушёл, чтобы заниматься любимым делом'); Z.setJob(s, j, 0); s.st.joy += 12; Z.logLine(s, 'Увлечение стало профессией: ' + Z.JOBS[j].n + '.', 'work'); return 'Ты превращаешь мечту в работу. Денег пока меньше. Счастья — несравнимо больше.'; } },
        { t: 'Оставить как увлечение', fx: 'joy+6', res: 'Пусть будет для души. Это тоже прекрасно.' }
      ]
    },
    {
      id: 'w_mentor', age: [42, 70], w: 7, if: function (s) { return working(s) && s.lvl >= 2; }, title: 'Ученик',
      text: 'Молодой сотрудник ходит за тобой хвостом. Он похож на тебя в двадцать пять — горячий, неуклюжий, с огнём в глазах.',
      choices: [
        { t: 'Взять под крыло', fx: 'joy+6 sk+2 +mentor', res: 'Ты учишь его всему, чему научился за две жизни. Однажды он скажет кому-то: «Мой учитель».', log: 'Стал наставником.' },
        { t: 'Некогда', fx: '', res: 'Он находит другого наставника.' }
      ]
    },
    {
      id: 'w_retire', prio: 2, age: [60, 90], if: function (s) { return working(s); }, title: 'Пенсия',
      text: 'Тебе предлагают проводы на пенсию. Торт, грамота, речи.',
      choices: [
        { t: 'Уйти на пенсию', run: function (s) { Z.quitJob(s, 'Вышел на пенсию'); s.f.retired = true; s.st.joy += 4; return 'Ты собираешь вещи со стола. Двадцать… тридцать… сорок лет. Теперь время — твоё.'; } },
        { t: 'Остаться — я ещё нужен', fx: 'sk+2', res: 'Ты остаёшься. Работа держит в тонусе.' }
      ]
    }
  ]);
})();
