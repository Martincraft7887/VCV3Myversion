import funkin.editors.charter.Charter;

function onStateSwitch(e) {
	if (e.substate is Charter) {
		FlxG.state.registerSmoothTransition();
		PLAY_CHARTER_TRANSITION = true;
	}
}