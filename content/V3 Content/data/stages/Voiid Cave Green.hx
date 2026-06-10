var heatShader:Dynamic = null;
var sparksShader:Dynamic = null;
var heatWaveActive:Bool = false;
var heatWaveAttached:Bool = false;
var sparkTime:Float = 0;
var skipStageSparks:Bool = false;

function postCreate() {
	enableHeatWave();
}

function onStageActivated(name:String) {
	enableHeatWave();
}

function onStageChanged(name:String) {
	updateSparks();
}

function onStageDeactivated(nextName:String) {
	disableHeatWave();
}

function destroy() {
	disableHeatWave();
}

function enableHeatWave() {
	if (heatWaveActive) return;

	heatShader = new CustomShader("legacy/HeatEffect");
	heatShader.hset("strength", 0.5);
	heatShader.hset("iTime", 0);

	skipStageSparks = songUsesModchartSparks();
	if (!skipStageSparks) {
		sparksShader = new CustomShader("legacy/SparkEffect");
		sparksShader.hset("iTime", 0);
		sparksShader.hset("red", 0.7);
		sparksShader.hset("green", 0.22);
		sparksShader.hset("blue", 0.95);
		sparksShader.hset("size", 140.0);
		sparksShader.hset("scale", 1.2);
		sparksShader.hset("warp", -250);
		sparksShader.hset("speed", 1.0);
	}

	camGame.addShader(heatShader);
	camHUD.addShader(heatShader);
	if (sparksShader != null) camHUD.addShader(sparksShader);

	heatWaveActive = true;
	heatWaveAttached = true;
	updateSparks();
	trace("[Volcano] heatWave loaded");
}

function disableHeatWave() {
	if (!heatWaveActive && !heatWaveAttached) return;

	if (heatShader != null) {
		try {
			camGame.removeShader(heatShader);
		} catch(e:Dynamic) {}
		try {
			camHUD.removeShader(heatShader);
		} catch(e:Dynamic) {}
	}
	if (sparksShader != null) {
		try {
			camHUD.removeShader(sparksShader);
		} catch(e:Dynamic) {}
	}

	heatShader = null;
	sparksShader = null;
	heatWaveActive = false;
	heatWaveAttached = false;
	trace("[Volcano] heatWave removed");
}

function songUsesModchartSparks():Bool {
	var songName = "";
	try {
		if (PlayState.SONG != null && PlayState.SONG.meta != null) {
			songName = PlayState.SONG.meta.name;
			if ((songName == null || songName == "") && PlayState.SONG.meta.displayName != null)
				songName = PlayState.SONG.meta.displayName;
		}
	} catch(e:Dynamic) {}

	return songName == "Greedoom" || songName == "Purgatory" || songName == "Krakatoa";
}

function updateSparks() {
	if (sparksShader == null) return;

	var stageName = curStage;
	if (PlayState.instance != null) stageName = PlayState.instance.curStage;

	if (stageName == "GreedVolcano" || stageName == "Voiid Cave Green" ) {
		sparksShader.hset("red", 0.57);
		sparksShader.hset("green", 1.0);
		sparksShader.hset("blue", 0.66);
		sparksShader.hset("warp", -500);
	} else if (stageName == "IgnisGladius" || stageName == "OGVolcano") {
		sparksShader.hset("red", 1.0);
		sparksShader.hset("green", 0.4);
		sparksShader.hset("blue", 0.1);
		sparksShader.hset("warp", -450);
	} else {
		sparksShader.hset("red", 0.8);
		sparksShader.hset("green", 0.26);
		sparksShader.hset("blue", 1.0);
		sparksShader.hset("warp", -400);
	}

	trace("[Volcano] sparks updated for stage: " + stageName);
}

function update(elapsed:Float) {
	if (!heatWaveActive) return;

	sparkTime += elapsed;
	var currentBeat = (Conductor.songPosition / 1000) * (Conductor.bpm / 60);

	if (heatShader != null) {
		heatShader.hset("iTime", Conductor.songPosition * 0.001);
		heatShader.hset("strength", 0.5 + Math.sin(currentBeat) * 0.25);
	}
	if (sparksShader != null) {
		sparksShader.hset("iTime", sparkTime);
	}
}
