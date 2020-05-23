var context;

var volume = 0.075;

function tone(f) {
  // reuse old context to see if we can avoid freezing the browser engine
  // on Android
  if(context) {
    context.close();
  }
  context = new AudioContext();

  var now = context.currentTime;

  var osc = createOscillator(f, "triangle", context, now);
  var osc2 = createOscillator(f, "square", context, now);

  // console.log("osc:", osc);
  osc.start(now);
  osc2.start(now);
  osc.stop(now + 2);
  osc2.stop(now + 2);
}

function createOscillator(f, type, context, now) {
  var osc = context.createOscillator();
  var gainOsc = context.createGain();
  gainOsc.gain.value = volume;

  osc.type = type;
  osc.frequency.value = f;

  var modOsc = context.createOscillator();
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

  gainOsc.gain.setValueAtTime(0.001, now);
  // console.log("gainOsc.gain.exponentialRampToValueAtTime:", gainOsc.gain.exponentialRampToValueAtTime);
  gainOsc.gain.exponentialRampToValueAtTime(volume, now + 0.025);
  gainOsc.gain.exponentialRampToValueAtTime(0.001, now + 2);

  return osc;
}
