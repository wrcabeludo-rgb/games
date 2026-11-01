// Тихий звук под каждый период жизни — синтезируется прямо в браузере (без файлов).
// Карандаши — гитара, гелевые ручки — лёгкое пианино, фломастеры — дождь и пианино, акрил — тёплые аккорды,
// акварель — мягкое пианино и птицы, простой карандаш — тишина и редкие ноты. В серый период — дождь.
(function () {
  'use strict';
  var Z = window.Z;
  var ctx = null, master = null, rain = null, timer = null, cur = null, on = false;
  var PRESET = {
    pencils:    { inst: 'guitar', every: 2600, chords: [[52, 59, 64, 67], [48, 55, 60, 64], [50, 57, 62, 65], [55, 59, 62, 67]], rain: 0 },
    gel:        { inst: 'piano', every: 3000, chords: [[60, 64, 67, 72], [57, 60, 64, 69], [53, 57, 60, 65], [55, 59, 62, 67]], rain: 0 },
    markers:    { inst: 'piano', every: 3600, chords: [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]], rain: 0.05 },
    acrylic:    { inst: 'pad', every: 4200, chords: [[48, 55, 60, 64], [45, 52, 57, 60], [41, 48, 53, 57], [43, 50, 55, 59]], rain: 0 },
    watercolor: { inst: 'piano', every: 4600, chords: [[72, 76, 79], [69, 72, 76], [65, 69, 72], [67, 71, 74]], rain: 0, birds: true },
    graphite:   { inst: 'piano', every: 6500, chords: [[64, 67], [60, 64], [62, 65], [59, 62]], rain: 0 },
    liner:      { inst: 'piano', every: 7500, chords: [[64], [67], [60], [62], [59]], rain: 0 },
    oneline:    { inst: 'piano', every: 9500, chords: [[72], [76], [79], [74]], rain: 0, birds: true }
  };
  function hz(n) { return 440 * Math.pow(2, (n - 69) / 12); }
  function init() {
    if (ctx) return true;
    var AC = window.AudioContext || window.webkitAudioContext; if (!AC) return false;
    ctx = new AC(); master = ctx.createGain(); master.gain.value = 0.0; master.connect(ctx.destination);
    // дождь: шум через фильтр
    var len = ctx.sampleRate * 2, buf = ctx.createBuffer(1, len, ctx.sampleRate), d = buf.getChannelData(0), last = 0;
    for (var i = 0; i < len; i++) { var w = Math.random() * 2 - 1; last = (last + 0.02 * w) / 1.02; d[i] = last * 3.5; }
    var src = ctx.createBufferSource(); src.buffer = buf; src.loop = true;
    var lp = ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 1400;
    rain = ctx.createGain(); rain.gain.value = 0; src.connect(lp); lp.connect(rain); rain.connect(master); src.start();
    return true;
  }
  function note(n, when, inst, vol) {
    var t = ctx.currentTime + when, f = hz(n);
    if (inst === 'guitar') { // Карплюс–Стронг: короткий шум в линии задержки
      var dl = ctx.createDelay(), fb = ctx.createGain(), lp = ctx.createBiquadFilter(), g = ctx.createGain();
      dl.delayTime.value = 1 / f; fb.gain.value = 0.985; lp.type = 'lowpass'; lp.frequency.value = 2400;
      var nb = ctx.createBuffer(1, Math.floor(ctx.sampleRate / f), ctx.sampleRate), nd = nb.getChannelData(0);
      for (var i = 0; i < nd.length; i++) nd[i] = Math.random() * 2 - 1;
      var ns = ctx.createBufferSource(); ns.buffer = nb;
      ns.connect(dl); dl.connect(lp); lp.connect(fb); fb.connect(dl); lp.connect(g); g.connect(master);
      g.gain.setValueAtTime(vol, t); g.gain.exponentialRampToValueAtTime(0.0001, t + 2.6);
      ns.start(t); setTimeout(function () { try { g.disconnect(); dl.disconnect(); } catch (e) { } }, (when + 3) * 1000);
      return;
    }
    var o = ctx.createOscillator(), o2 = ctx.createOscillator(), gg = ctx.createGain();
    o.type = inst === 'pad' ? 'sawtooth' : 'triangle'; o2.type = 'sine'; o.frequency.value = f; o2.frequency.value = f * 2.001;
    var flt = ctx.createBiquadFilter(); flt.type = 'lowpass'; flt.frequency.value = inst === 'pad' ? 900 : 2600;
    o.connect(flt); o2.connect(flt); flt.connect(gg); gg.connect(master);
    var att = inst === 'pad' ? 0.8 : 0.01, rel = inst === 'pad' ? 3.5 : 2.4;
    gg.gain.setValueAtTime(0.0001, t); gg.gain.exponentialRampToValueAtTime(vol, t + att); gg.gain.exponentialRampToValueAtTime(0.0001, t + att + rel);
    o.start(t); o2.start(t); o.stop(t + att + rel + 0.1); o2.stop(t + att + rel + 0.1);
  }
  function bird(when) {
    var t = ctx.currentTime + when, o = ctx.createOscillator(), g = ctx.createGain();
    o.type = 'sine'; o.frequency.setValueAtTime(2600, t); o.frequency.exponentialRampToValueAtTime(3600, t + 0.08); o.frequency.exponentialRampToValueAtTime(2900, t + 0.16);
    g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(0.015, t + 0.02); g.gain.exponentialRampToValueAtTime(0.0001, t + 0.18);
    o.connect(g); g.connect(master); o.start(t); o.stop(t + 0.2);
  }
  function loop() {
    if (!on || !cur) return;
    var P = PRESET[cur.style] || PRESET.pencils, ch = P.chords[Math.floor(Math.random() * P.chords.length)];
    var arp = P.inst === 'guitar' ? 0.22 : P.inst === 'pad' ? 0 : 0.35;
    ch.forEach(function (n, i) { note(n, i * arp + Math.random() * 0.05, P.inst, P.inst === 'pad' ? 0.035 : P.inst === 'guitar' ? 0.09 : 0.05); });
    if (P.birds && Math.random() < 0.5) { bird(1.2); bird(1.45); }
    timer = setTimeout(loop, P.every * (0.85 + Math.random() * 0.3));
  }
  Z.Sound = {
    // Вызывать после касания экрана (на телефоне иначе звук не включится)
    set: function (enabled, style, gray) {
      on = !!enabled;
      if (!on) { if (master && ctx) master.gain.setTargetAtTime(0, ctx.currentTime, 0.4); clearTimeout(timer); timer = null; return; }
      if (!init()) return;
      if (ctx.state === 'suspended') ctx.resume();
      master.gain.setTargetAtTime(0.55, ctx.currentTime, 0.8);
      var P = PRESET[style] || PRESET.pencils;
      rain.gain.setTargetAtTime(gray ? 0.11 : P.rain, ctx.currentTime, 1.5);
      var changed = !cur || cur.style !== style;
      cur = { style: style, gray: gray };
      if (changed || !timer) { clearTimeout(timer); timer = setTimeout(loop, 600); }
    }
  };
  // Вибрация в важные моменты (на iPhone браузер её не поддерживает — там просто ничего не происходит)
  Z.buzz = function (pattern) { try { if (navigator.vibrate) navigator.vibrate(pattern || 25); } catch (e) { } };
})();
