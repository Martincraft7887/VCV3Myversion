//original code by LJ, edited by Malloy

// Configurable variables (edit these as needed)
public static var botplay:Bool = false; // default ON
public static var toggleKey:String = "SEVEN"; // keybind: number 7
public static var blockInputs:Bool = true; // cancel inputs while botplay
public static var perfectBotHits:Bool = true;
public static var botHitLeadMs:Float = 8;

var _allowedGitaroo:Bool = allowGitaroo;

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

function syncBotplayFromSave() {
    botplay = saveBool("voiidBotplay", botplay);
}

function setBotplay(value:Bool) {
    botplay = value;
    Reflect.setField(FlxG.save.data, "voiidBotplay", botplay);
    FlxG.save.flush();
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
    canDie = !(botplay || noDeathEnabled());
    if (_allowedGitaroo) allowGitaroo = !botplay;
    playerStrums.forEach((strum) -> { strum.cpu = botplay; });
    try {
        if (strumLines != null && strumLines.members != null && strumLines.members[1] != null)
            strumLines.members[1].cpu = botplay;
    } catch(e:Dynamic) {}
}

function update(elapsed) {
    syncBotplayFromSave();

    if (isTogglePressed()) {
        setBotplay(!botplay);
        return;
    }

    applyBotplayState();
}

function postCreate() {
    syncBotplayFromSave();
    applyBotplayState();

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
                PlayState.instance.goodNoteHit(daNote.strumLine, daNote);
            } catch(e:Dynamic) {
                Conductor.songPosition = oldSongPosition;
                throw e;
            }
            Conductor.songPosition = oldSongPosition;
            return;
        }

        PlayState.instance.goodNoteHit(daNote.strumLine, daNote);
    }
}

function onNoteHit(e) {
    if (e.note.strumLine == strumLines.members[1] && !e.note.isSustainNote) {
        e.showSplash = true;
    }
}
