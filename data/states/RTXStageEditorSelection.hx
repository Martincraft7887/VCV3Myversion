import funkin.editors.EditorTreeMenu.EditorTreeMenuScreen;
import funkin.editors.ui.UIState;
import funkin.game.Stage;
import haxe.io.Path;
import funkin.options.type.TextOption;

var stageList:Array<String> = [];

function postCreate() {
	stageList = Stage.getList(false);
	for (path in Paths.getFolderContent("data/stages/", true)) {
		if (Path.extension(path) == "json") {
			var stageName = Path.withoutDirectory(Path.withoutExtension(path));
			if (!stageList.contains(stageName))
				stageList.push(stageName);
		}
	}
	stageList.sort(function(a, b) return Reflect.compare(a.toLowerCase(), b.toLowerCase()));

	var screen = new EditorTreeMenuScreen("RTX Stage Editor", "Select a stage to edit.", "rtxStageEditorSelection.");
	addMenu(screen);

	for (stageName in stageList)
		screen.add(makeStageOption(stageName, screen));

	bgType = "stage";
}

function makeStageOption(stageName:String, parentScreen) {
	return new TextOption(stageName, parentScreen.getID("acceptStage"), "", function() {
		var state = new UIState();
		state.scriptName = "RTXStageEditor";
		Reflect.setField(FlxG.save.data, "rtxStageEditorStage", stageName);
		FlxG.switchState(state);
	});
}
