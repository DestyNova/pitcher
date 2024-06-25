var context;

var volume = 0.1;

function autoCleanup(osc) {
  osc.onended = function() { osc.disconnect(); };
}

function playTones(fs) {
  fs.forEach(f => tone(f));
}

function tone(f) {
  if(!context) {
    context = new AudioContext();
  }

  var now = context.currentTime;

  var osc = createOscillator(f, "triangle", context, now);
  var osc2 = createOscillator(f, "square", context, now);

  osc.start(now);
  osc2.start(now);
  osc.stop(now + 2);
  osc2.stop(now + 2);
}

function createOscillator(f, type, context, now) {
  var osc = context.createOscillator();
  autoCleanup(osc);
  var gainOsc = context.createGain();
  autoCleanup(gainOsc);
  gainOsc.gain.value = volume;

  osc.type = type;
  osc.frequency.value = f;

  var modOsc = context.createOscillator();
  autoCleanup(modOsc);
  var modGain = context.createGain();
  modOsc.frequency.value = f;
  modGain.gain.value = f * 0.25 * 0.01

  // filters
  hiFilter = context.createBiquadFilter();
  hiFilter.frequency.value = 50;
  hiFilter.type = 'highpass';
  loFilter = context.createBiquadFilter();
  loFilter.frequency.value = 12000;
  loFilter.type = 'lowpass';

  modOsc.connect(modGain);
  modGain.connect(osc.frequency);
  osc.connect(hiFilter);
  hiFilter.connect(loFilter);
  loFilter.connect(gainOsc);
  gainOsc.connect(context.destination);

  const dur = 0.75;
  gainOsc.gain.setValueAtTime(0.001, now);
  gainOsc.gain.setValueAtTime(0, now + dur + 0.01);
  // console.log("gainOsc.gain.exponentialRampToValueAtTime:", gainOsc.gain.exponentialRampToValueAtTime);
  gainOsc.gain.exponentialRampToValueAtTime(volume, now + 0.025);
  gainOsc.gain.exponentialRampToValueAtTime(0.0001, now + dur);

  return osc;
}
