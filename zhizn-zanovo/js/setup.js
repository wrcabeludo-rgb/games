// Анкета: кем ты был в прошлой жизни.
(function () {
  'use strict';
  var Z = window.Z;
  var AGE_OPTS = [['a', 'До 25 лет', 22], ['b', '25–35 лет', 30], ['c', '35–45 лет', 40], ['d', 'После 45', 48]];
  function ageOpts(su) { return AGE_OPTS.filter(function (o) { return o[2] < su.age; }).map(function (o) { return [o[0], o[1]]; }); }

  // Шаги анкеты. show — нужен ли шаг; type: one | text | multi
  Z.SETUP = [
    { k: 'name', type: 'text', q: 'Как тебя зовут?', ph: 'Андрей', hint: 'Так к тебе будут обращаться в игре.' },
    { k: 'age', type: 'one', q: 'Сколько тебе лет сейчас?', hint: 'Игра закончится, когда ты снова доживёшь до этого возраста. Потом можно жить дальше.', o: [[30, '30'], [40, '40'], [50, '50'], [60, '60']] },
    { k: 'married', type: 'one', q: 'Ты был женат?', o: [['never', 'Не был'], ['married', 'Женат и сейчас'], ['divorced', 'Разведён'], ['widow', 'Вдовец']] },
    { k: 'wifeName', type: 'text', q: 'Как её зовут?', ph: 'Имя', hint: 'Ты встретишь её снова. Что будет дальше — решать тебе.', show: function (su) { return su.married && su.married !== 'never'; } },
    { k: 'wifeType', type: 'one', q: 'Где вы познакомились?', show: function (su) { return su.married && su.married !== 'never'; },
      o: [['anya', 'Однокурсница'], ['katya', 'Яркая девушка из компании, творческая'], ['lena', 'Девушка из родного двора'], ['marina', 'Врач или медсестра'], ['olga', 'Коллега по работе']] },
    { k: 'why', type: 'one', q: 'Почему вы расстались?', hint: 'Игра напомнит тебе об этом в нужный момент.', show: function (su) { return su.married === 'divorced'; },
      o: [['work', 'Я пропадал на работе'], ['fights', 'Ссоры из-за мелочей'], ['goals', 'Хотели разного'], ['cheat', 'Измена'], ['drink', 'Алкоголь'], ['other', 'Сложно сказать']] },
    { k: 'wifeAge', type: 'one', q: 'Сколько тебе было, когда её не стало?', show: function (su) { return su.married === 'widow'; }, o: ageOpts },
    { k: 'kids', type: 'one', q: 'Сколько у тебя детей?', o: [[0, 'Нет'], [1, 'Один'], [2, 'Двое'], [3, 'Трое и больше']] },
    { k: 'parents', type: 'one', q: 'Твои родители живы?', hint: 'В игре они снова будут живы. И у тебя будет шанс.', o: [['both', 'Оба живы'], ['mom', 'Жива только мама'], ['dad', 'Жив только папа'], ['none', 'Их уже нет']] },
    { k: 'dadAge', type: 'one', q: 'Сколько тебе было, когда не стало папы?', show: function (su) { return su.parents === 'mom' || su.parents === 'none'; }, o: ageOpts },
    { k: 'momAge', type: 'one', q: 'Сколько тебе было, когда не стало мамы?', show: function (su) { return su.parents === 'dad' || su.parents === 'none'; }, o: ageOpts },
    { k: 'lostFriend', type: 'one', q: 'Твои друзья живы?', o: [[false, 'Да, все'], [true, 'Я потерял друга']] },
    { k: 'lostName', type: 'text', q: 'Как звали друга?', ph: 'Имя', show: function (su) { return su.lostFriend; } },
    { k: 'lostFem', type: 'one', q: 'Это был друг или подруга?', show: function (su) { return su.lostFriend; }, o: [[false, 'Друг'], [true, 'Подруга']] },
    { k: 'lostCause', type: 'one', q: 'Что случилось?', hint: 'В игре у тебя будет шанс оказаться рядом.', show: function (su) { return su.lostFriend; },
      o: [['crash', 'Авария'], ['ill', 'Болезнь'], ['drink', 'Алкоголь'], ['depr', 'Депрессия'], ['lost', 'Мы просто потеряли друг друга']] },
    { k: 'job', type: 'one', q: 'Кем ты работаешь?', grid: true,
      o: function () { return Object.keys(Z.JOBS).filter(function (id) { return id !== 'biz'; }).map(function (id) { return [id, Z.cap(Z.JOBS[id].n)]; }).concat([['biz', 'Предприниматель'], ['other', 'Другое']]); } },
    { k: 'regrets', type: 'multi', q: 'Что бы ты хотел изменить?', hint: 'Выбери до трёх. В конце игра покажет, получилось ли.', max: 3,
      o: function () { return Object.keys(Z.REGRETS).map(function (k) { return [k, Z.REGRETS[k]]; }); } },
    { k: 'tempo', type: 'one', q: 'Как подробно проживать жизнь?', hint: 'Можно поменять потом в меню.', o: [['slow', 'Подробно — много событий'], ['normal', 'Обычно'], ['fast', 'Быстро — только главное']] }
  ];
  Z.setupSteps = function (su) { return Z.SETUP.filter(function (st) { return !st.show || st.show(su); }); };
  Z.stepOpts = function (st, su) { return typeof st.o === 'function' ? st.o(su) : st.o; };
})();
