function onPlayerHit(e)
    if (e.noteType == "Caution Half")
        health + 2.1;
function onDadHit(e)
    if (e.noteType == "Caution Half")
        health + 2.1;
function onPlayerMiss(e) {
	if (e.noteType == "Caution Half"){
		health - 100;
	}
}

function onNoteCreation(e) {
    if (e.noteType == "Caution Half"){
		e.noteSprite = "game/notes/Caution Half";
		e.note.updateHitbox();
	}
}
