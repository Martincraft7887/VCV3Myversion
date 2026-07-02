


public static var botplay:Bool = false; 
public static var toggleKey:String = "SEVEN"; 
public static var blockInputs:Bool = true; 
public static var perfectBotHits:Bool = true;
public static var botHitLeadMs:Float = 8;

var _allowedGitaroo:Bool = allowGitaroo;
var cachedBotplay:Bool = false;
var cachedNoDeath:Bool = false;
var noDeathDied:Bool = false;
var noDeathDeathHealth:Float = 0.05;

function saveBool(name:String, fallback:Bool):Bool {
    var value = Reflect.field(FlxG.save.data, name);
    if (value == null) {
        Reflect.setField(FlxG.save.data, name, fallback);
        FlxG.save.flush();
        return fallback;
    }
    return value == true;
}

function noDeathEnabled():Bool {
    return saveBool("voiidNoDeath", false);
}

function syncOptionsFromSave(force:Bool = false) {
    var savedBotplay = saveBool("voiidBotplay", botplay);
    var savedNoDeath = noDeathEnabled();
    if (!force && savedBotplay == cachedBotplay && savedNoDeath == cachedNoDeath)
        return;

    botplay = savedBotplay;
    cachedBotplay = savedBotplay;
    cachedNoDeath = savedNoDeath;
    applyBotplayState();
}

function refreshVoiidAssistOptions() {
    syncOptionsFromSave(true);
}

function setBotplay(value:Bool) {
    if (botplay == value && saveBool("voiidBotplay", value) == value)
        return;

    botplay = value;
    Reflect.setField(FlxG.save.data, "voiidBotplay", botplay);
    FlxG.save.flush();
    cachedBotplay = botplay;
    cachedNoDeath = noDeathEnabled();
    applyBotplayState();
}

function isTogglePressed():Bool {
    if (FlxG.keys.justPressed.SEVEN) return true;
    try {
        return FlxG.keys.justPressed[toggleKey];
    } catch(e:Dynamic) {}
    return false;
}

function applyBotplayState() {
    canDie = !(botplay || cachedNoDeath);
    if (_allowedGitaroo) allowGitaroo = !botplay;
    try {
        if (strumLines != null && strumLines.members != null && strumLines.members[1] != null)
            strumLines.members[1].cpu = botplay;
    } catch(e:Dynamic) {}
}

function markNoDeathDied() {
    if (noDeathDied)
        return;

    noDeathDied = true;
    Reflect.setField(FlxG.save.data, "voiidNoDeathDied", true);
    FlxG.save.flush();
}

function checkNoDeathDied() {
    if (!cachedNoDeath || noDeathDied)
        return;

    try {
        if (health <= 0) {
            markNoDeathDied();
            health = noDeathDeathHealth;
        }
    } catch(e:Dynamic) {}
}

function botGoodNoteHit(strumLine, daNote:Note) {
    var oldCpu = strumLine.cpu;
    var oldScore = songScore;
    var oldCombo = combo;
    var oldRatingNum = ratingNum;
    var oldAccuracyPressedNotes = accuracyPressedNotes;
    var oldTotalAccuracyAmount = totalAccuracyAmount;

    strumLine.cpu = false;
    try {
        PlayState.instance.goodNoteHit(strumLine, daNote);
    } catch(e:Dynamic) {
        strumLine.cpu = oldCpu;
        throw e;
    }
    strumLine.cpu = oldCpu;

    songScore = oldScore;
    combo = oldCombo;
    ratingNum = oldRatingNum;
    accuracyPressedNotes = oldAccuracyPressedNotes;
    totalAccuracyAmount = oldTotalAccuracyAmount;
    updateRating();
}

function update(elapsed) {
    syncOptionsFromSave();
    checkNoDeathDied();

    if (isTogglePressed()) {
        setBotplay(!botplay);
        return;
    }
}

function postCreate() {
    noDeathDied = false;
    Reflect.setField(FlxG.save.data, "voiidNoDeathDied", false);
    FlxG.save.flush();

    syncOptionsFromSave(true);

    strumLines.forEach(function(strum) {
        if (strum.cpu) return;
        strum.onNoteUpdate.add(updateNote);
    });
}

function onInputUpdate(event) {
    if (blockInputs && botplay) event.cancel();
}

function updateNote(event) {
    if (!botplay) return;

    var daNote:Note = event.note;
    if (daNote.avoid || daNote.wasGoodHit) return;
    if (daNote.strumTime <= Conductor.songPosition + botHitLeadMs) {
        if (perfectBotHits) {
            var oldSongPosition = Conductor.songPosition;
            Conductor.songPosition = daNote.strumTime;
            try {
                botGoodNoteHit(daNote.strumLine, daNote);
            } catch(e:Dynamic) {
                Conductor.songPosition = oldSongPosition;
                throw e;
            }
            Conductor.songPosition = oldSongPosition;
            return;
        }

        botGoodNoteHit(daNote.strumLine, daNote);
    }
}

function onNoteHit(e) {
    if (e.note.strumLine == strumLines.members[1] && !e.note.isSustainNote) {
        e.showSplash = true;
    }
}
