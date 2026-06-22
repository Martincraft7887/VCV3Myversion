function onPlayerHit(e) {
    if (e.noteType == "Fire Ball")
        triggerGameOver();
}

function onDadHit(e) {
    if (e.noteType == "Fire Ball")
        health + 2.1;
}

function onPlayerMiss(e) {
    if (e.noteType == "Fire Ball") {
        e.cancel();
        deleteNote(e.note);
        e.preventAnim(e.note);
    }
}

function onNoteCreation(e) {
    if (e.noteType == "Fire Ball") {
        e.noteSprite = "game/notes/Fire Ball";
        e.note.updateHitbox();

        e.note.avoid = true;
        e.note.earlyPressWindow = 0.1;
        e.note.latePressWindow = 0.1;
    }
}

function triggerGameOver() {
    gameOver(boyfriend);
}