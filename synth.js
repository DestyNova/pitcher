function tone(f) {
  console.log(0);
  var context = new AudioContext();
  var now = context.currentTime;

  var osc = createOscillator(f, "triangle", context, now);
  var osc2 = createOscillator(f, "sine", context, now);

  osc.start(now);
  osc2.start(now);
  osc.stop(now + 2);
  osc2.stop(now + 2);
}

function createOscillator(f, type, context, now) {
  var osc = context.createOscillator();
  var gainOsc = context.createGain();

  osc.type = type;
  osc.frequency.value = f;

  osc.connect(gainOsc);
  gainOsc.connect(context.destination);

  gainOsc.gain.setValueAtTime(0.001, now);
  console.log("gainOsc.gain.exponentialRampToValueAtTime:", gainOsc.gain.exponentialRampToValueAtTime);
  gainOsc.gain.exponentialRampToValueAtTime(1.0, now + 0.025);
  gainOsc.gain.exponentialRampToValueAtTime(0.001, now + 2);
  return osc;
}
