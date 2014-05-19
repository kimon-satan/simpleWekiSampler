//Simple Weki Sampler


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


//set up environment variables
(

~sampleArray = Array.newClear();


)


//TODO
// work out sensible data structure ... probably 2 dictionaries
// updating file view based on dictionaries
// osc node
// tempo clock
// looping ?

//load a basic gui
(

var w, addSample, sampleSelector, moveUp, moveDown, delButt, loadSample, playSample, clearAll, currentSample = 0;

w = Window("simpleSamplePlayer", Rect(0, 0, 640, 480)).front;
w.view.decorator = FlowLayout(w.view.bounds);

sampleSelector = EZListView.new(w,200@230, " List:")
.setColors(Color.grey, Color.white);

loadSample = {
	Dialog.openPanel({ arg path;

		var item;

		item = path.split;
		item = item[item.size()-1].asSymbol;

		("loading " ++ path ++ "... ").postln;

		~sampleArray = ~sampleArray.add(
			Buffer.read(s, path);
		);

		sampleSelector.addItem(item, {|a| a.postln; });




		},{
			"cancelled".postln;
	});
};


addSample = ActionButton(w,"add sample",loadSample ,minWidth: 100, minHeight: 40);

moveUp = ActionButton(w,"move up list",{
	"move up list".postln
},minWidth: 100, minHeight: 40);

moveDown = ActionButton(w,"move down list",{
	"move down list".postln
},minWidth: 100, minHeight: 40);

delButt = ActionButton(w,"delete from bank",{
	"delete from bank".postln
},minWidth: 100, minHeight: 40);

clearAll = ActionButton(w,"clear all samples",{
	"clear all samples".postln;
	~sampleArray.size().do{|c|~sampleArray[c].free;}
},minWidth: 100, minHeight: 40);

playSample = ActionButton(w,"play Sample",{
	"play Sample".postln;
	if(~sampleArray.size() > 0, {
		x = Synth.new(\simplePlayerMono, [\bufNum, ~sampleArray[0]]);
	});
},minWidth: 100, minHeight: 40);



)






