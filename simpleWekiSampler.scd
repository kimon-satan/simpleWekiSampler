//Simple Weki Sampler

NetAddr.langPort

//load the synthdefs

(

SynthDef.new(\simplePlayerMono, {|bufNum, loop = 0, trig = 1, rate = 1, pos = 0, amp = 0|

	var sig;

	sig = PlayBuf.ar(1, bufNum, rate: rate, startPos: pos * BufFrames.kr(bufNum), loop: loop);
	sig = Pan2.ar(sig , 0) * amp;
	sig = sig * EnvGen.kr(Env.asr(0.01,1,0.2),trig,doneAction:2);
	Out.ar(0, sig);
}).send(s);

SynthDef.new(\simplePlayerStereo, {|bufNum, amp = 0, loop = 0, trig = 1, rate = 1, pos = 0|

	var sig;

	sig = PlayBuf.ar(2, bufNum, rate: rate, startPos: pos * BufFrames.kr(bufNum), loop: loop);
	sig = Pan2.ar(sig , 0) * amp;
	sig = sig * EnvGen.kr(Env.asr(0.01,1,0.2),trig,doneAction:2);
	Out.ar(0, sig);

}).send(s);

)



//TODO

// tempo clock
// looping ?

//load a basic gui
(

var w, addSample, sampleSelector, moveUp, moveDown,
delButt, loadSample, playSample, clearAll, currentSample = 0,
selSamplesBut, selSamplesFunc, selSamplesList, selSamples, selRates, selRateFunc, isMet;
//beats variables
var avPhraseLength = 4,
loopSynths = Array.newClear(4),
metronome, tempoClock, currBeat, tempoSlide, port, rateMod = 1;

port = NetAddr.new("192.168.1.3", 7771);    // create the NetAddr


tempoClock = TempoClock.new;

w = Window("simpleSamplePlayer", Rect(0, 0, 640, 480)).front;

f = FlowView.new(w, Rect(0,0,320,480));
g = FlowView.new(w, Rect(320,0,320,480));


~sampleArray = Array.newClear();


loadSample = {
	Dialog.openPanel({ arg path;

		avPhraseLength = 0;

		path.size().do{|i|
			var item, label;

			item = path[i];
			label = path[i];
			label = label.split;
			label = label[label.size()-1].asSymbol;

			//("loading " ++ item ++ "... ").postln;

			~sampleArray = ~sampleArray.add(
				Buffer.read(s, item);
			);


			sampleSelector.addItem(label);
			currentSample = 0;
		};

		{
			2.wait;

			~sampleArray.size().do{|count|
				avPhraseLength = avPhraseLength + ~sampleArray[count].numFrames;
			};

			avPhraseLength = avPhraseLength/~sampleArray.size();
			tempoClock.tempo = 1/(avPhraseLength/(44100*16));

			metronome = Task({

				currBeat = -1;

				loop{
					currBeat = (currBeat + 1)%16;
					//("beat" ++ currBeat).postln;
					if(isMet == true, {x = {SinOsc.ar(1000,0, EnvGen.kr(Env.perc(0.01,0.05), doneAction:2)) * 0.1}.play});
					port.sendMsg("/beat", currBeat);

					if(currBeat == 0){

						tempoClock.schedAbs(0, {

							selSamples.size().do{|count|
								var amp = 0;
								if(currentSample == count){amp = 0.5};
								loopSynths[count].set(\trig,0);
								loopSynths[count] = Synth.new(\simplePlayerMono, [
									\bufNum, selSamples[count],
									\loop, 1, \rate, selRates[count], \pos, 0, \amp, amp
								]);
							};
							nil;
						});

					};


					1.wait;
				}

			}).play(tempoClock);



		}.fork;

		},{
			"cancelled".postln;
	},true);
};


selSamplesFunc = {

	var sel, isValid, indexes;

	loopSynths.size().do{|count|
		loopSynths[count].set(\trig, 0);
	};

	selSamplesList.items = Array.new();
	if(~sampleArray.size() >= 4){

		selSamples = Array.new();
		selRates = Array.newClear(4);


		4.do{


			isValid = false;

			while({isValid == false}){
				var label;
				sel = ~sampleArray.choose;
				if(selSamples.includes(sel) == false){
					selSamples = selSamples.add(sel);
					label = sel.path;
					label = label.split;
					label = label[label.size()-1].asSymbol;
					selSamplesList.addItem(label);
					isValid = true;

				}
			}
		};


		selRateFunc.value;

		currBeat = -1; // will retrigger the new samples





	};

	nil;

};


selRateFunc = {

	4.do{|count|
			var rate;

			rate = selSamples[count].numFrames/avPhraseLength * rateMod;
			if(rate > 1.5,{
				rate = rate/2;
			});

			if(rate < 0.5, {
				rate = rate * 2;
			});

			selRates[count] = rate * 2;

		};


};


sampleSelector = EZListView.new(f,200@230, " List:",

	globalAction: { |a| currentSample = a.value }

)
.setColors(Color.grey, Color.white);

f.startRow;

addSample = ActionButton(f,"add sample",loadSample ,minWidth: 100, minHeight: 40);


selSamplesList = EZListView.new(g,200@230, " SelSamples:").setColors(Color.grey, Color.white);
selSamplesBut = ActionButton(g,"sel samples",{

	currentSample = 4;
	selSamplesFunc.value;
	}

	,minWidth: 100, minHeight: 40);




moveUp = ActionButton(f,"move up list",{
	"move up list".postln;
	if(currentSample != 0, {
		var sampleName;
		sampleName = sampleSelector.item;

		~sampleArray = ~sampleArray.swap(currentSample, currentSample -1);

		sampleSelector.removeItemAt(currentSample);
		sampleSelector.insertItem(
			currentSample - 1,
			sampleName.asSymbol,
			{}
		);
		sampleSelector.valueAction = currentSample - 1;



	})
},minWidth: 100, minHeight: 40);

moveDown = ActionButton(f,"move down list",{
	"move down list".postln;
	if(currentSample != (~sampleArray.size() - 1), {
		var sampleName;
		sampleName = sampleSelector.item;
		~sampleArray = ~sampleArray.swap(currentSample, currentSample + 1);

		sampleSelector.removeItemAt(currentSample);
		sampleSelector.insertItem(
			currentSample + 1,
			sampleName.asSymbol
		);
		sampleSelector.valueAction = currentSample + 1;
	})
},minWidth: 100, minHeight: 40);

delButt = ActionButton(f,"delete from bank",{
	~sampleArray[currentSample].free;
	~sampleArray.removeAt(currentSample);
	sampleSelector.removeItemAt(currentSample);
	sampleSelector.valueAction = 0;
},minWidth: 100, minHeight: 40);

clearAll = ActionButton(f,"clear all samples",{
	"clear all samples".postln;
	~sampleArray.size().do{|c|
		~sampleArray[c].free;
		sampleSelector.removeItemAt(0);
	};

},minWidth: 100, minHeight: 40);

playSample = ActionButton(f,"play Sample",{
	if(~sampleArray.size() > 0, {
		x = Synth.new(\simplePlayerMono, [\bufNum, ~sampleArray[currentSample]]);
	});
},minWidth: 100, minHeight: 40);



4.do{|count|

	var lbl = "play " ++ (count + 1);

	ActionButton(g, lbl,{
		var pos;
		currentSample = count;
		if(selSamples.size() > 0){
			4.do{|ct|
				if(ct != count,{loopSynths[ct].set(\amp, 0)});
			};
			loopSynths[count].set(\amp, 0.5);
		}
	}, minWidth: 50, minHeight: 30);


};

tempoSlide = Slider(g, Rect(20, 100, 100, 20))
    .action_({
	//(tempoSlide.value + 0.5).postln;
	rateMod = (tempoSlide.value + 0.5);
	tempoClock.tempo = 1/(avPhraseLength/(44100*16))* rateMod;
	selRateFunc.value;

	selRates.size().do{|count|
		loopSynths[count].set(\rate, selRates[count]);
	};

        }).background_(Color.rand)
.value = 0.5;

ToggleButton(g, "metronome",{ isMet = true; },{ isMet = false; });

w.onClose = {

	~sampleArray.size().do{|c|
		~sampleArray[c].free;
	};

	loopSynths.size().do{|count|
		loopSynths[count].set(\trig,0);
	};

	metronome.stop;
	OSCdef(\param).clear;
};

//the OSC node


OSCdef(\param, {|msg|

	if(currentSample != msg[1], {
		//msg.postln;
		currentSample = msg[1];

		if(currentSample == 4,

			{
				AppClock.sched(0,selSamplesFunc);

			}, {

				if(selSamples.size() > 0){
					4.do{|ct|
						if(ct != currentSample,{loopSynths[ct].set(\amp, 0)});
					};
					loopSynths[currentSample].set(\amp, 0.5);
				}

			}

		);

	});


}, '/OSCSynth/params');

)











