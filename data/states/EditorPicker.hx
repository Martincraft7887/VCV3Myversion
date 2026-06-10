//
import funkin.editors.ui.UIState;
import funkin.editors.EditorPicker;
import flixel.effects.FlxFlicker;
import funkin.editors.EditorTreeMenu;
import Type;

var modchartEditorID = 5;
var rtxStageEditorID = 6;

function create()
{
	options.push(
		{
			name: "Modchart Editor",
			id: "modchart-editor",
			iconID: 0,
			state: EditorTreeMenu
		}
	);
	modchartEditorID = options.length-1;

	options.push(
		{
			name: "RTX Editor",
			id: "rtx-stage-editor",
			iconID: 2,
			state: EditorTreeMenu
		}
	);
	rtxStageEditorID = options.length-1;
	
}
var didSelect = false;
function postUpdate(elapsed)
{
	if (!didSelect)
	{
		if (selected)
		{
			didSelect = true;
			if (curSelected == modchartEditorID)
				overrideStateLoad("ModchartEditorSelection");
			if (curSelected == rtxStageEditorID)
				overrideStateLoad("RTXStageEditorSelection");
		}
	}

}

function overrideStateLoad(script) {
	FlxFlicker.stopFlickering(sprites[curSelected].label); //stop currrent callback
	sprites[curSelected].flicker(function() {
		subCam.fade(0xFF000000, 0.25, false, function() {
			var state = Type.createInstance(options[curSelected].state, []);
			state.scriptName = script;
			FlxG.switchState(state);
		});
	});
}
