//Simple Weki Sampler

NetAddr.langPort

//load the synthdefs

(

SynthDef.new(\simplePlayerMono, {|bufNum, amp = 0.5|

	var sig;

	sig = PlayBuf.ar(1, bufNum, doneAction:2);
	sig = Pan2.ar(sig , 0) * amp;
	Out.ar(0, sig);
}).send(s);

SynthDef.new(\simplePlayerStereo, {|bufNum, amp = 0.5|

	var sig;

	sig = PlayBuf.ar(2, bufNum, doneAction:2);
	sig = Pan2.ar(sig , 0) * amp;
	Out.ar(0, sig);

}).send(s);

)



//TODO

// tempo clock
// looping ?

//load a basic gui
(

var w, addSample, sampleSelector, moveUp, moveDown, delButt, loadSample, playSample, clearAll, currentSample = 0;

w = Window("simpleSamplePlayer", Rect(0, 0, 640, 480)).front;
w.view.decorator = FlowLayout(w.view.bounds);

~sampleArray = Array.newClear();

sampleSelector = EZListView.new(w,200@230, " List:",

	globalAction: { |a| currentSample = a.value }

)
.setColors(Color.grey, Color.white);


loadSample = {
	Dialog.openPanel({ arg path;

		path.size().do{|i|
			var item, label;

			item = path[i];
			label = path[i];
			label = label.split;
			label = label[label.size()-1].asSymbol;

			("loading " ++ item ++ "... ").postln;

			~sampleArray = ~sampleArray.add(
				Buffer.read(s, item);
			);

			sampleSelector.addItem(label);
			currentSample = 0;
		}


		},{
			"cancelled".postln;
	},true);
};



addSample = ActionButton(w,"add sample",loadSample ,minWidth: 100, minHeight: 40);


moveUp = ActionButton(w,"move up list",{
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

moveDown = ActionButton(w,"move down list",{
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

delButt = ActionButton(w,"delete from bank",{
	~sampleArray[currentSample].free;
	~sampleArray.removeAt(currentSample);
	sampleSelector.removeItemAt(currentSample);
	sampleSelector.valueAction = 0;
},minWidth: 100, minHeight: 40);

clearAll = ActionButton(w,"clear all samples",{
	"clear all samples".postln;
	~sampleArray.size().do{|c|
		~sampleArray[c].free;
		sampleSelector.removeItemAt(0);
	};

},minWidth: 100, minHeight: 40);

playSample = ActionButton(w,"play Sample",{
	"play Sample".postln;
	if(~sampleArray.size() > 0, {
		x = Synth.new(\simplePlayerMono, [\bufNum, ~sampleArray[currentSample]]);
	});
},minWidth: 100, minHeight: 40);

w.onClose = {

	~sampleArray.size().do{|c|
		~sampleArray[c].free;
	};

	OSCdef(\param).clear;
};

//the OSC node


OSCdef(\param, {|msg|

	if(currentSample != msg[1], {
		//msg.postln;
		currentSample = msg[1];
		if(~sampleArray.size() > 0, {
		x = Synth.new(\simplePlayerMono, [\bufNum, ~sampleArray[currentSample]]);
	});

	});


}, '/OSCSynth/params');



)











