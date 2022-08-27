// 
// 2022.08.27 byulparan@gmail.com
// SungminPark
// 




(
s.boot;
s.meter.window.alwaysOnTop_(true);
s.freqscope.window.alwaysOnTop_(true);
)

(
~reverbBus = 60;
~delayBus = 62;
)

(
~scale = Scale.lydian;

SynthDef(\pad, {|dur = 6.0|
	var freqs = ({ (TChoose.kr(1,~scale.degrees) + 48).midicps * IRand(1,4) } ! 8);
	var amps = { LFNoise1.kr(4).range(0.01, 0.4)} ! 8;
	var noises = Klank.ar(`[freqs], PinkNoise.ar(0.005));
	var sigs = Splay.ar(SinOsc.ar(freqs, 0, amps), 1.0, 0.6) + Pan2.ar(noises);
	var env = EnvGen.kr(Env.new([0, 1, 1, 0], [0.3, 0.4, 0.3]*dur), doneAction:2);
	sigs = sigs * env * 0.6;
	Out.ar(0, sigs);
	Out.ar(~reverbBus, sigs*0.1);
	Out.ar(~delayBus, sigs* 0.3);
}).add;


SynthDef(\kick, {
	var sig = Pan2.ar(SinOsc.ar(EnvGen.kr(Env.new([800,50],[0.03])), 0, EnvGen.kr(Env.perc(0.0,1.0,0.6), doneAction:2)));
	sig = sig*0.5;
	Out.ar(0, sig);
	Out.ar(~delayBus, sig* 0.1);
}).add;


SynthDef(\hihat, {|dur=1|
	var sig = Pan2.ar(HPF.ar(WhiteNoise.ar(EnvGen.kr(Env.new([0.13,0.0],[dur*0.5]), doneAction:2)), 8000));
	Out.ar(0, sig*0.6);
}).add;


SynthDef(\piano, {|gain = 1.0, reverb = 0.1, delay = 0.3|
	var sig = VSTPlugin.ar(nil, 2) * 1.4 * gain ;
	Out.ar(~reverbBus, sig*reverb);
	Out.ar(~delayBus, sig*delay);
	Out.ar(0, sig);
}).add;
)






(
var efxGroup = Group.new(1, \addAfter);
{
	Mix(GVerb.ar(In.ar(~reverbBus, 2), 100, 6.0));	
}.play(efxGroup);

{
	CombN.ar(In.ar(~delayBus, 2), 4.0, [0.25, 0.21], 4.0);
}.play(efxGroup);


// If you don't have pianoteq. You should be change VST instrument. 
~pianoVST = VSTPluginController(Synth(\piano)).open("Pianoteq 7");

~piano = {|note,vel,dur| Routine{ s.makeBundle(s.latency, {~pianoVST.midi.noteOn(0,note,vel)}); dur.wait; ~pianoVST.midi.noteOff(0,note,0)}.play  }; 
)


~pianoVST.editor;

(
Pdef(\pad,
	Pbind(
		\instrument, \pad,
		\dur, 14.0,
		\delta, 8.0
	)
).quant_(1).play;
)

(
Pdef(\kick,
	Pbind(
		\instrument, \kick,
		\delta, Pxrand([0.5, 0.25, 1,2,3,4,6,8].collect({|n| Pseq([1/n], if(n > 1, n, 1)) }) , inf)
	)
).quant_(1).play;
)


(
Tdef(\left_piano, {
	inf.do{
		~piano.(36, 60, 1);
		1.wait;
	}
}).play(quant:1)
)


(
Tdef(\right_piano, {
	inf.do{
		var note = ~scale.degrees.choose + [60,72].choose;
		var n = 1.rrand(3);
		~piano.(note, 70, 2);
		n.do {
			Routine{
				var note = ~scale.degrees.choose + [60,72,84].choose;
				[0.125,0.25,0.5].choose.wait;
				~piano.(note, 60, 1.0);
			}.play;
		};
		[1,2].choose.wait;
	}
}).play(quant:1);
)

Tdef(\right_piano).stop;
Tdef(\left_piano).stop;
Pdef(\kick).stop;
Pdef(\pad).stop;