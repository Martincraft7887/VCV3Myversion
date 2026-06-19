import funkin.backend.utils.DiscordUtil;
import funkin.backend.utils.WindowUtils;

var discordCleared:Bool = false;

function getSavedBool(field:String, def:Bool):Bool {
	var value = Reflect.field(FlxG.save.data, field);
	if (value == null) {
		Reflect.setField(FlxG.save.data, field, def);
		FlxG.save.flush();
		return def;
	}
	return value == true;
}

function discordRpcEnabled():Bool {
	return getSavedBool("voiidDiscordRpc", true);
}

function dynamicWindowRpcEnabled():Bool {
	return getSavedBool("voiidDynamicWindowRpc", true);
}

function getSongDisplayName():String {
	if (PlayState.SONG == null || PlayState.SONG.meta == null)
		return null;

	var songName = PlayState.SONG.meta.displayName;
	if (songName == null || songName == "" || Std.string(songName) == "null")
		songName = PlayState.SONG.meta.name;

	return Std.string(songName);
}

function getDifficultyDisplayName():String {
	var diff = "";
	try {
		diff = Std.string(PlayState.difficulty);
	} catch(e:Dynamic) {}

	if (diff == null || diff == "" || diff == "null")
		return "";
	return diff.toUpperCase();
}

function getPlayModeRPCText():String {
	try {
		if (PlayState.isStoryMode) {
			if (PlayState.storyWeek != null && PlayState.storyWeek.name != null && Std.string(PlayState.storyWeek.name) != "")
				return "Story Mode: " + Std.string(PlayState.storyWeek.name);
			return "Story Mode";
		}
	} catch(e:Dynamic) {}
	return "Freeplay";
}

function getMissesText():String {
	try {
		if (PlayState.instance != null)
			return Std.string(PlayState.instance.misses);
	} catch(e:Dynamic) {}
	return "0";
}

function isHiddenSong(songName:String):Bool {
	if (songName == null)
		return false;
	var hiddenSongs = [
		"punch and gun", "venom", "power link", "revenge", "final destination", "disadvantage", "champion", "last combat",
		"greedoom", "purgatory", "krakatoa", "cosmic memories", "new horizon", "galactic storm", "warm up", "king hit wawa",
		"edgelord", "final destination old", "recovery", "take it", "fishycuffs", "cleverness", "tempo slayer", "total bravery",
		"mattpurgation", "1core killer", "bombastic", "ignit gladius", "exodus", "wastelands", "toxic", "wii remote",
		"ballin", "interregnum", "defamation of reality", "radical showdown", "glowing collision", "paired entities",
		"multiversal slash", "sweet dreams", "boxing match vip", "tko vip", "alter ego vip", "rejected vip"
	];
	return hiddenSongs.contains(songName.toLowerCase());
}

function getLeatherPortraitKey():String {
	var songName = getSongDisplayName();
	if (songName == null)
		return "logo";

	switch(songName.toLowerCase()) {
		case "light it up" | "ruckus" | "target practice":
			return "wiik1";
		case "burnout" | "sporting" | "boxing match" | "sport swinging" | "boxing gladiators":
			return "wiik2";
		case "flaming glove" | "punch and gun" | "venom":
			return "fg";
		case "fisticuffs" | "blastout" | "immortal" | "king hit" | "king hit wawa":
			return "wiik3";
		case "tko" | "tko vip":
			return "tko";
		case "recovery" | "ignition" | "last combat" | "champion":
			return "wiik4";
		case "sweet dreams":
			return "sweetdreams";
		case "mat" | "banger" | "edgy":
			return "wiik100";
		case "alter ego" | "alter ego vip":
			return "alterego";
		case "rejected" | "rejected vip":
			return "rejected";
		case "1core killer" | "1 core killer":
			return "1corekiller";
		case "average voiid song":
			return "averagelordvoiidsong";
	}
	return "logo";
}

function getSongRPCText():String {
	if (PlayState.SONG == null || PlayState.SONG.meta == null)
		return null;

	var songName = getSongDisplayName();
	var diff = getDifficultyDisplayName();

	if (!dynamicWindowRpcEnabled())
		return songName + (diff == "" ? "" : " (" + diff + ")");

	return (isHiddenSong(songName) ? "???" : songName) + " (" + diff + ", Misses: " + getMissesText() + ")";
}

function getDetailsRPCText(prefix:String = ""):String {
	if (!dynamicWindowRpcEnabled())
		return prefix == "" ? (PlayState.instance != null && PlayState.instance.paused ? "Paused" : "Playing") : prefix;

	var details = getPlayModeRPCText();
	if (prefix != null && prefix != "")
		return prefix + " - " + details;
	if (PlayState.instance != null && PlayState.instance.paused)
		return "Paused - " + details;
	return details;
}

function getOpponentRPCIcon():String {
	try {
		if (PlayState.instance != null && PlayState.instance.dad != null) {
			var icon = PlayState.instance.dad.getIcon();
			if (icon != null && icon != "")
				return icon;
		}
	} catch(e:Dynamic) {}

	try {
		var icon = PlayState.instance.getIconRPC();
		if (icon != null && icon != "")
			return icon;
	} catch(e:Dynamic) {}

	return null;
}

function onGameOver() {
	if (!discordRpcEnabled()) {
		DiscordUtil.clearPresence();
		return;
	}
	DiscordUtil.changePresence(getDetailsRPCText("Game Over"), getSongRPCText(), getOpponentRPCIcon());
}

function onDiscordPresenceUpdate(e) {
	var data = e.presence;

	if (!discordRpcEnabled()) {
		if (!discordCleared) {
			discordCleared = true;
			DiscordUtil.clearPresence();
		}
		e.cancel();
		return;
	}
	discordCleared = false;

	if(data.button1Label == null)
		data.button1Label = "Download";
	if(data.button1Url == null)
		data.button1Url = "https://www.mediafire.com/file/cnt6fw5xlrd6sp6/Voiid_Chronicles_Restored.rar/file";

	if (dynamicWindowRpcEnabled() && PlayState.instance != null && PlayState.SONG != null) {
		data.largeImageKey = getLeatherPortraitKey();
		data.largeImageText = "Voiid Chronicles";
	}

	if (data.smallImageText == null && data.smallImageKey != null)
		data.smallImageText = data.smallImageKey;
}

function onPlayStateUpdate() {
	if (!discordRpcEnabled()) {
		DiscordUtil.clearPresence();
		return;
	}

	DiscordUtil.changeSongPresence(
		getDetailsRPCText(),
		getSongRPCText(),
		PlayState.instance.inst,
		getOpponentRPCIcon()
	);
}

function onMenuLoaded(name:String) {
	if (!discordRpcEnabled()) {
		DiscordUtil.clearPresence();
		return;
	}

	DiscordUtil.changePresenceSince(name, null);
	if (StringTools.startsWith(WindowUtils.winTitle, "Voiid Chronicles"))
	{
		DiscordUtil.currentID = "1030560676923588739";
	}
}

function onEditorTreeLoaded(name:String) {
	if (!discordRpcEnabled()) {
		DiscordUtil.clearPresence();
		return;
	}

	switch(name) {
		case "Character Editor":
			DiscordUtil.changePresenceSince("Character Editor", "Choosing a Character");
		case "ModchartEditor":
			DiscordUtil.changePresenceSince("Modchart Editor", "Choosing a Modchart");
		case "Chart Editor":
			DiscordUtil.changePresenceSince("Chart Editor", "Choosing a Chart");
		case "Stage Editor":
			DiscordUtil.changePresenceSince("Stage Editor", "Choosing a Stage");
		default:
			DiscordUtil.changePresenceSince(name, null);
	}
}

function onEditorLoaded(name:String, editingThing:String) {
	if (!discordRpcEnabled()) {
		DiscordUtil.clearPresence();
		return;
	}

	switch(name) {
		case "Character Editor":
			DiscordUtil.changePresenceSince("Character Editor", editingThing);
		case "Chart Editor":
			DiscordUtil.changePresenceSince("Chart Editor", editingThing);
		case "ModchartEditor":
			DiscordUtil.changePresenceSince("Modchart Editor", editingThing);
		case "Stage Editor":
			DiscordUtil.changePresenceSince("Stage Editor", editingThing);
		default:
			DiscordUtil.changePresenceSince(name, editingThing);
	}
}
