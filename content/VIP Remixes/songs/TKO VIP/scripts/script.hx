var drunkStrength = 0;
var drunkSpeed = 1;
var tipsyStrengthX = 0;
var tipsyStrengthY = 0;
var tipsySpeed = 1;

function postCreate() {
    
    drunkStrength = 0;  
    tipsyStrengthX = 0;
    tipsyStrengthY = 0;
}

function updatePost(elapsedFloat) {
    var bpm = 120; 
var songTime = 0;

function postCreate() {
    
    setDrunk(0, 1);
    setTipsy(0, 0, 1);
}

function updatePost(elapsedFloat) {
    songTime = Conductor.songPosition; 

    function beatToMs(beat:Float):Float {
        return (beat / bpm) * 60000;
    }

    
    function easeCircInOut(t:Float):Float {
        return t < 0.5 ? (1 - Math.sqrt(1 - 4 * (t * t))) / 2 : (Math.sqrt(-((2 * t) - 3) * ((2 * t) - 1)) + 1) / 2;
    }

    function easeCircOut(t:Float):Float {
        return Math.sqrt(1 - ((t - 1) * (t - 1)));
    }

    function easeCubeIn(t:Float):Float {
        return t * t * t;
    }

    function easeCubeInOut(t:Float):Float {
        return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
    }

    
    function interpolate(startVal:Float, endVal:Float, t:Float, easingFunc):Float {
        var easedT = easingFunc(t);
        return startVal + (endVal - startVal) * easedT;
    }

    
    function runEvent(startBeat:Float, lengthBeats:Float, startVal:Float, endVal:Float, easingFunc, setFunc:Dynamic) {
        var startMs = beatToMs(startBeat);
        var lengthMs = beatToMs(lengthBeats);
        if (songTime >= startMs && songTime <= startMs + lengthMs) {
            var t = (songTime - startMs) / lengthMs;
            var val = interpolate(startVal, endVal, t, easingFunc);
            setFunc(val);
        }
    }

    
    static var currentTipsyX = 0;
    static var currentTipsyY = 0;

    
    function setDrunkHelper(val:Float) {
        setDrunk(val, 1);
    }

    function setTipsyXHelper(val:Float) {
        currentTipsyX = val;
        setTipsy(currentTipsyX, currentTipsyY, 1);
    }

    function setTipsyYHelper(val:Float) {
        currentTipsyY = val;
        setTipsy(currentTipsyX, currentTipsyY, 1);
    }

    

    
    runEvent(252, 12, 0, 5, easeCircInOut, setDrunkHelper);
    runEvent(256, 4, 5, 0, easeCircOut, setDrunkHelper);
    runEvent(575, 4, 0, 0.2, easeCubeIn, setDrunkHelper);
    runEvent(592, 12, 0.2, 0, easeCubeInOut, setDrunkHelper);

    
    runEvent(542, 8, 0, 0.4, easeCubeIn, setTipsyXHelper);
    runEvent(575, 4, 0.4, 1, easeCubeIn, setTipsyXHelper);
    runEvent(592, 48, 1, 0, easeCubeInOut, setTipsyXHelper);

    
    runEvent(542, 8, 0, 0.3, easeCubeIn, setTipsyYHelper);
    runEvent(575, 4, 0.3, 0, easeCubeIn, setTipsyYHelper);
    runEvent(592, 48, 0, 0, easeCubeInOut, setTipsyYHelper);
}

    var songTime = Conductor.songPosition / 1000;  
    var keyCount = PlayState.keyCount;

    for (lane in 0...keyCount) {
        
        var laneOffsetDrunk = (lane % 4) * 0.2;
        var drunkOffset = Math.cos(songTime * drunkSpeed + laneOffsetDrunk) * 56 * drunkStrength;
        setKeyXOffset(lane, drunkOffset);

        
        var laneOffsetTipsyX = (lane % 2 == 0 ? 1 : -1);
        var tipsyXOffset = Math.sin(songTime * tipsySpeed) * 56 * tipsyStrengthX * laneOffsetTipsyX;
        addKeyXOffset(lane, tipsyXOffset);  

        
        var laneOffsetTipsyY = (lane % 2 == 0 ? 1 : -1);
        var tipsyYOffset = Math.cos(songTime * tipsySpeed) * 56 * tipsyStrengthY * laneOffsetTipsyY;
        setKeyYOffset(lane, tipsyYOffset);
    }
}


function setDrunk(strengthFloat, speedFloat) {
    drunkStrength = strengthFloat;
    if (speedFloat != null) drunkSpeed = speedFloat;
}

function setTipsy(xStrengthFloat, yStrengthFloat, speedFloat) {
    tipsyStrengthX = xStrengthFloat;
    tipsyStrengthY = yStrengthFloat;
    if (speedFloat != null) tipsySpeed = speedFloat;
}
