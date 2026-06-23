import funkin.game.PlayState;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.backend.FunkinText;
import funkin.backend.MusicBeatState;
import funkin.backend.scripting.ModSubState;
import flixel.FlxG;
import lime.utils.Assets;

var awardData:Array<Dynamic> = [
	{name: "Wiik 1", save: "beat_wiik 1", image: "Wiik1", songs: ["light it up", "ruckus", "target practice"]},
	{name: "Light it Up FC", save: "fc_light it up", image: "Wiik1FC", song: "light it up"},
	{name: "Ruckus FC", save: "fc_ruckus", image: "Wiik1FC", song: "ruckus"},
	{name: "Target Practice FC", save: "fc_target practice", image: "Wiik1FC", song: "target practice"},
	{name: "Wiik 2", save: "beat_wiik 2", image: "Wiik2", songs: ["burnout", "sporting", "boxing match"]},
	{name: "Burnout FC", save: "fc_burnout", image: "Wiik2FC", song: "burnout"},
	{name: "Sporting FC", save: "fc_sporting", image: "Wiik2FC", song: "sporting"},
	{name: "Boxing Match FC", save: "fc_boxing match", image: "Wiik2FC", song: "boxing match"},
	{name: "Wiik 3", save: "beat_wiik 3", image: "Wiik3", songs: ["fisticuffs", "blastout", "immortal", "king hit"]},
	{name: "Fisticuffs FC", save: "fc_fisticuffs", image: "Wiik3FC", song: "fisticuffs"},
	{name: "Blastout FC", save: "fc_blastout", image: "Wiik3FC", song: "blastout"},
	{name: "Immortal FC", save: "fc_immortal", image: "Wiik3FC", song: "immortal"},
	{name: "King Hit FC", save: "fc_king hit", image: "Wiik3FC", song: "king hit"},
	{name: "Wiik 100", save: "beat_wiik 100", image: "Wiik100", songs: ["mat", "banger", "edgy"]},
	{name: "Mat FC", save: "fc_mat", image: "Wiik100FC", song: "mat"},
	{name: "Banger FC", save: "fc_banger", image: "Wiik100FC", song: "banger"},
	{name: "Edgy FC", save: "fc_edgy", image: "Wiik100FC", song: "edgy"},
	{name: "Alter Ego FC", save: "fc_alter ego", image: "AlterEgo", song: "alter ego"},
	{name: "Rejected FC", save: "fc_rejected", image: "Rejected", song: "rejected"}
];

var awardPopupDelay:Float = 0;
var activeAwardPopups:Int = 0;
var awardsCheckedThisSong:Bool = false;
var allowRealSongEnd:Bool = false;
var resultsOpen:Bool = false;
var glovesCheckedThisSong:Bool = false;

var WHITE_GLOVE_FIELD:String = "voiidWhiteGloves";
var PURPLE_GLOVE_FIELD:String = "voiidPurpleGloves";
var WHITE_GLOVE_TOTAL_FIELD:String = "voiidWhiteGlovesEarnedTotal";
var PURPLE_GLOVE_TOTAL_FIELD:String = "voiidPurpleGlovesEarnedTotal";
var PENDING_GLOVE_FIELD:String = "voiidPendingGloves";
var GLOVE_SAVE_FIELD:String = "voiidGloveSave";

function awardSaveField(save:String):String {
	return "voiid_award_" + save;
}

function getSongName():String {
	if (PlayState.SONG == null || PlayState.SONG.meta == null)
		return "";
	var songName = PlayState.SONG.meta.name;
	if (songName == null || songName == "")
		songName = PlayState.SONG.meta.displayName;
	return songName == null ? "" : Std.string(songName).toLowerCase();
}

function isBotplayAwardBlocked():Bool {
	return Reflect.field(FlxG.save.data, "voiidBotplay") == true;
}

function isValidCompletion():Bool {
	return Reflect.field(FlxG.save.data, "voiidBotplay") != true
		&& Reflect.field(FlxG.save.data, "voiidNoDeath") != true
		&& !PlayState.chartingMode;
}

function normalSongKey(name:String):String {
	if (name == null) return "";
	var key:String = StringTools.trim(Std.string(name).toLowerCase());
	key = StringTools.replace(key, " ", "");
	key = StringTools.replace(key, "-", "");
	key = StringTools.replace(key, "_", "");
	key = StringTools.replace(key, "'", "");
	key = StringTools.replace(key, "\"", "");
	return key;
}

function songCompleteField(songName:String):String {
	return "voiid_song_complete_" + normalSongKey(songName);
}

function markSongComplete(songName:String) {
	if (songName == "" || !isValidCompletion()) return;
	Reflect.setField(FlxG.save.data, songCompleteField(songName), true);
	FlxG.save.flush();
}

function markCurrentSongCompleteAliases(songName:String) {
	if (!isValidCompletion()) return;
	markSongComplete(songName);
	if (PlayState.SONG != null && PlayState.SONG.meta != null) {
		if (PlayState.SONG.meta.name != null)
			markSongComplete(Std.string(PlayState.SONG.meta.name));
		if (PlayState.SONG.meta.displayName != null)
			markSongComplete(Std.string(PlayState.SONG.meta.displayName));
	}
}

function saveStoryProgress(songName:String) {
	if (!PlayState.isStoryMode || PlayState.storyWeek == null || PlayState.storyPlaylist == null)
		return;

	var weekName = Std.string(PlayState.storyWeek.name);
	var remaining = PlayState.storyPlaylist.length;
	if (remaining > 1) {
		var completedCount = 0;
		if (PlayState.storyWeek.songs != null)
			completedCount = PlayState.storyWeek.songs.length - remaining + 1;
		Reflect.setField(FlxG.save.data, "voiid_story_progress_" + normalSongKey(weekName), completedCount);
		Reflect.setField(FlxG.save.data, "voiid_story_progress_song_" + normalSongKey(weekName), PlayState.storyPlaylist[1]);
	} else {
		Reflect.setField(FlxG.save.data, "voiid_story_complete_" + normalSongKey(weekName), true);
		Reflect.deleteField(FlxG.save.data, "voiid_story_progress_" + normalSongKey(weekName));
		Reflect.deleteField(FlxG.save.data, "voiid_story_progress_song_" + normalSongKey(weekName));
	}
	FlxG.save.flush();
}

function getGloveSave():Dynamic {
	var data = Reflect.field(FlxG.save.data, GLOVE_SAVE_FIELD);
	if (data == null) {
		data = {};
		Reflect.setField(FlxG.save.data, GLOVE_SAVE_FIELD, data);
	}

	for (field in [WHITE_GLOVE_FIELD, PURPLE_GLOVE_FIELD, WHITE_GLOVE_TOTAL_FIELD, PURPLE_GLOVE_TOTAL_FIELD]) {
		var oldValue = Reflect.field(FlxG.save.data, field);
		if (oldValue != null && Reflect.field(data, field) == null)
			Reflect.setField(data, field, oldValue);
	}

	return data;
}

function getSavedInt(field:String):Int {
	var value = Reflect.field(getGloveSave(), field);
	if (value == null)
		return 0;
	var parsed = Std.parseInt(Std.string(value));
	return parsed == null ? 0 : parsed;
}

function addSavedInt(field:String, amount:Int) {
	Reflect.setField(getGloveSave(), field, getSavedInt(field) + amount);
}

function queueGlovePopup(name:String, amount:Int, imagePath:String) {
	if (amount <= 0)
		return;

	var pending:Array<Dynamic> = Reflect.field(FlxG.save.data, PENDING_GLOVE_FIELD);
	if (pending == null) pending = [];
	pending.push({
		name: name,
		amount: amount,
		desc: "+" + amount,
		imagePath: imagePath,
		title: "Gloves earned!"
	});
	Reflect.setField(FlxG.save.data, PENDING_GLOVE_FIELD, pending);
}

function getPlayerNoteCount():Int {
	try {
		if (PlayState.SONG != null && PlayState.SONG.strumLines != null) {
			var playerIndex = PlayState.opponentMode ? 0 : 1;
			if (playerIndex >= 0 && playerIndex < PlayState.SONG.strumLines.length && PlayState.SONG.strumLines[playerIndex] != null && PlayState.SONG.strumLines[playerIndex].notes != null)
				return PlayState.SONG.strumLines[playerIndex].notes.length;
		}
	} catch(e:Dynamic) {}
	return 0;
}

function getPlayerKeyCount():Int {
	try {
		if (PlayState.SONG != null && PlayState.SONG.strumLines != null) {
			var playerIndex = PlayState.opponentMode ? 0 : 1;
			if (playerIndex >= 0 && playerIndex < PlayState.SONG.strumLines.length && PlayState.SONG.strumLines[playerIndex] != null && PlayState.SONG.strumLines[playerIndex].keyCount != null)
				return Std.int(PlayState.SONG.strumLines[playerIndex].keyCount);
		}
	} catch(e:Dynamic) {}
	return 4;
}

function getSongMultiplier():Float {
	try {
		if (PlayState.instance != null && Reflect.hasField(PlayState.instance, "songMultiplier")) {
			var value = Std.parseFloat(Std.string(Reflect.field(PlayState.instance, "songMultiplier")));
			return Math.isNaN(value) ? 1 : value;
		}
	} catch(e:Dynamic) {}
	return 1;
}

function getWhiteGloveSongMultiplier(songName:String):Float {
	var songKey = normalSongKey(songName);
	var diffKey = "";
	try {
		if (PlayState.difficulty != null)
			diffKey = normalSongKey(PlayState.difficulty);
	} catch(e:Dynamic) {}
	switch(songKey) {
		case "finaldestinationgod": return 2.5;
		case "krakatoa": return 1.5;
		case "rejected": return 2;
		case "rejectedvip": return 2.5;
		case "finaldestinationvip": return 2.5;
		case "finaldestinationvipold": return 2.5;
		case "kinghitvip": return 1.5;
		case "tkovip": return 1.5;
		case "sweetdreamsii": return 2.5;
	}
	if (songKey == "finaldestination" && diffKey == "god")
		return 2.5;
	return 1;
}

function earnSongGlovesNow() {
	if (glovesCheckedThisSong)
		return;
	glovesCheckedThisSong = true;

	var ps = PlayState.instance;
	if (ps == null || isBotplayAwardBlocked())
		return;

	var noteCount = getPlayerNoteCount();
	if (noteCount <= 0)
		return;

	var keyMult = Math.max(1, getPlayerKeyCount()) / 4.0;
	var misses = ps.misses;
	var w:Float = noteCount - (misses * (40 / keyMult));
	if (w < noteCount * 0.4)
		w = noteCount * 0.4;

	var acc = ps.accuracy;
	if (acc > 1)
		acc *= 0.01;
	if (acc < 0)
		acc = 0;
	if (acc > 1)
		acc = 1;

	w *= Math.max(0, getSongMultiplier());
	w *= acc;
	w *= 0.1;
	w *= getWhiteGloveSongMultiplier(getSongName());

	var whiteGain = Math.floor(w);
	if (whiteGain <= 0)
		return;

	var oldTotal = getSavedInt(WHITE_GLOVE_TOTAL_FIELD);
	var newTotal = oldTotal + whiteGain;
	var purpleGain = Math.floor(newTotal / 250) - Math.floor(oldTotal / 250);

	addSavedInt(WHITE_GLOVE_FIELD, whiteGain);
	addSavedInt(WHITE_GLOVE_TOTAL_FIELD, whiteGain);
	if (purpleGain > 0) {
		addSavedInt(PURPLE_GLOVE_FIELD, purpleGain);
		addSavedInt(PURPLE_GLOVE_TOTAL_FIELD, purpleGain);
	}

	queueGlovePopup("White Gloves", whiteGain, "main menu/freeplay/glove_white");
	queueGlovePopup("Purple Gloves", purpleGain, "main menu/freeplay/glove_lean");
	FlxG.save.flush();
}

function unlockAward(award:Dynamic) {
	if (award == null || Reflect.field(FlxG.save.data, awardSaveField(award.save)) == true)
		return;

	Reflect.setField(FlxG.save.data, awardSaveField(award.save), true);

	var pending:Array<Dynamic> = Reflect.field(FlxG.save.data, "voiidPendingAwards");
	if (pending == null) pending = [];
	pending.push({name: award.name, desc: award.desc == null ? "Award unlocked!" : award.desc, image: award.image});
	Reflect.setField(FlxG.save.data, "voiidPendingAwards", pending);

	FlxG.save.flush();
}

function unlockSongAwardsNow() {
	if (awardsCheckedThisSong)
		return;

	awardsCheckedThisSong = true;

	var songName = getSongName();
	if (songName == "")
		return;

	markCurrentSongCompleteAliases(songName);
	saveStoryProgress(songName);
	unlockWeekIfComplete(songName);

	var ps = PlayState.instance;
	if (ps != null && ps.misses == 0 && isValidCompletion())
		unlockAward(getFCAward(songName));
}

function resolvePopupImage(award:Dynamic):String {
	if (award != null && award.imagePath != null)
		return Std.string(award.imagePath);

	var iconPath = "awards/" + Std.string(award.image);
	if (!Assets.exists(Paths.image(iconPath)))
		iconPath = "awards/default";
	return iconPath;
}

function showAwardPopup(award:Dynamic):Bool {
	var ps = PlayState.instance;
	if (ps == null || award == null)
		return false;

	var delay = awardPopupDelay;
	awardPopupDelay += 0.7;

	if (delay <= 0) {
		createAwardPopup(award);
		new FlxTimer().start(0.85, function(_) {
			awardPopupDelay = Math.max(0, awardPopupDelay - 0.7);
		});
	} else {
		new FlxTimer().start(delay, function(_) {
			createAwardPopup(award);
			new FlxTimer().start(0.85, function(_) {
				awardPopupDelay = Math.max(0, awardPopupDelay - 0.7);
			});
		});
	}

	return true;
}

function createAwardPopup(award:Dynamic) {
	var w:Int = 400;
	var h:Int = 120;
	var targetY:Float = activeAwardPopups * h;
	var startY:Float = -h - 8;
	var x:Float = FlxG.width - w;
	var objects:Array<Dynamic> = [];
	activeAwardPopups++;

	var bg = new FlxSprite(x, startY).makeGraphic(w, h, 0xFF000000);
	bg.cameras = [camHUD];
	bg.scrollFactor.set();
	add(bg);
	objects.push(bg);

	var popupTitle = award.title == null ? Std.string(award.name) : Std.string(award.title);
	var title = new FunkinText(x + 5, startY + 5, w - 110, popupTitle, 32, true);
	title.font = Paths.font("Contb___.ttf");
	title.borderSize = 1.5;
	title.cameras = [camHUD];
	title.scrollFactor.set();
	add(title);
	objects.push(title);

	var descText = award.desc == null || Std.string(award.desc) == "" ? "Award unlocked!" : Std.string(award.desc);
	var desc = new FunkinText(x + 5, startY + 45, w - 110, descText, 16, true);
	desc.font = Paths.font("Contb___.ttf");
	desc.borderSize = 1;
	desc.cameras = [camHUD];
	desc.scrollFactor.set();
	add(desc);
	objects.push(desc);

	var iconPath = resolvePopupImage(award);
	var icon = new FlxSprite(x + w - 105, startY + 10).loadGraphic(Paths.image(iconPath));
	icon.setGraphicSize(100, 100);
	icon.updateHitbox();
	icon.antialiasing = Options.antialiasing;
	icon.cameras = [camHUD];
	icon.scrollFactor.set();
	add(icon);
	objects.push(icon);

	function sync() {
		title.y = bg.y + 5;
		desc.y = bg.y + 45;
		icon.y = bg.y + 10;
	}

	FlxTween.tween(bg, {y: targetY}, 0.45, {
		ease: FlxEase.quartOut,
		onUpdate: function(_) {
			sync();
		},
		onComplete: function(_) {
			new FlxTimer().start(4.8, function(_) {
				FlxTween.tween(bg, {y: startY}, 0.35, {
					ease: FlxEase.quadIn,
					onUpdate: function(_) {
						sync();
					},
					onComplete: function(_) {
						for (obj in objects) {
							remove(obj);
							obj.destroy();
						}
						activeAwardPopups = Math.max(0, activeAwardPopups - 1);
					}
				});
			});
		}
	});
}

function getFCAward(songName:String):Dynamic {
	for (award in awardData)
		if (award.song != null && Std.string(award.song).toLowerCase() == songName)
			return award;
	return null;
}

function unlockWeekIfComplete(songName:String) {
	if (!isValidCompletion()) return;
	for (award in awardData) {
		if (award.songs == null)
			continue;

		var songs:Array<String> = award.songs;
		if (!songs.contains(songName))
			continue;

		if (PlayState.isStoryMode && PlayState.storyPlaylist != null && PlayState.storyPlaylist.length <= 1) {
			unlockAward(award);
			return;
		}
	}
}

function onSongEnd(event) {
	if (resultsOpen) {
		event.cancel();
		return;
	}

	if (allowRealSongEnd)
		return;

	earnSongGlovesNow();
	unlockSongAwardsNow();

	event.cancel();
	resultsOpen = true;
	if (PlayState.instance != null) {
		PlayState.instance.canPause = false;
		PlayState.instance.paused = true;
		PlayState.instance.persistentUpdate = false;
		PlayState.instance.persistentDraw = true;
		PlayState.instance.openSubState(new ModSubState("VoiidResultsSubstate"));
	}
}

function finishVoiidResults() {
	if (allowRealSongEnd)
		return;

	allowRealSongEnd = true;
	resultsOpen = false;

	if (PlayState.instance != null) {
		PlayState.instance.paused = false;
		PlayState.instance.persistentUpdate = true;

		if (PlayState.isStoryMode && PlayState.storyPlaylist != null && PlayState.storyPlaylist.length > 1) {
			var ps = PlayState.instance;
			PlayState.campaignScore += ps.songScore;
			PlayState.campaignMisses += ps.misses;
			PlayState.campaignAccuracyTotal += ps.accuracy;
			PlayState.campaignAccuracyCount++;
			PlayState.storyPlaylist.shift();
			if (PlayState.storyVariations != null && PlayState.storyVariations.length > 0)
				PlayState.storyVariations.shift();

			var nextVariation = (PlayState.storyVariations != null && PlayState.storyVariations.length > 0) ? PlayState.storyVariations[0] : null;
			MusicBeatState.skipTransIn = false;
			MusicBeatState.skipTransOut = false;
			PlayState.__loadSong(PlayState.storyPlaylist[0], PlayState.difficulty, nextVariation);
			FlxG.switchState(new PlayState());
		} else {
			PlayState.instance.endSong();
		}
	}
}
