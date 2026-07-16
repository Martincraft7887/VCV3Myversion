import haxe.io.Path;

var globalScriptsFolder:String = "global scripts/";
var preferredGlobalScriptOrder:Array<String> = [
	"vcContentNoteTypes",
	"vcNoteTypes",
	"v2echos",
	"vc",
	"vcUI",
	"vcModcharts",
	"rtxLighting",
	"characterAndStageChanges",
	"songname",
	"voiidAwards",
	"scores",
	"crono",
	"Skip",
	"LJ Botplay",
	"extraCharFade",
	"punchMechanic",
	"wiik3punching",
	"doubleNoteGhosts",
	"Punching",
	"timer"
];

var globalSongScripts:Array<String> = [];

function addGlobalScript(path:String) {
	if (path == null || Path.extension(path) != "hx") return;

	var file = CoolUtil.getFilename(path);
	if (!globalSongScripts.contains(file))
		globalSongScripts.push(file);
}

for (path in Paths.getFolderContent(globalScriptsFolder, true, null))
	addGlobalScript(path);

globalSongScripts.sort(function(a:String, b:String):Int {
	var aIndex = preferredGlobalScriptOrder.indexOf(a);
	var bIndex = preferredGlobalScriptOrder.indexOf(b);

	if (aIndex == -1) aIndex = 10000;
	if (bIndex == -1) bIndex = 10000;

	if (aIndex < bIndex) return -1;
	if (aIndex > bIndex) return 1;

	var al = a.toLowerCase();
	var bl = b.toLowerCase();
	if (al < bl) return -1;
	if (al > bl) return 1;
	return 0;
});

for (scriptName in globalSongScripts)
	importScript(globalScriptsFolder + scriptName + ".hx");
