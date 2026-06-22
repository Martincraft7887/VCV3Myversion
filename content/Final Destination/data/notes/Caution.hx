function onPlayerHit(e)
    if (e.noteType == "Caution")
        health + 2.1;
function onDadHit(e)
    if (e.noteType == "Caution")
        health + 2.1;

function onPlayerMiss(e) {
	if (e.noteType == "Caution"){
     triggerGameOver();
	}
}

function onNoteCreation(e) {
    if (e.noteType == "Caution"){
		e.noteSprite = "game/notes/Caution";
		e.note.updateHitbox();
	}
}

function triggerGameOver() {
    gameOver(boyfriend); 
}