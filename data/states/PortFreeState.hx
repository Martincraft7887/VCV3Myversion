import funkin.backend.scripting.ModState;
import funkin.backend.utils.CoolUtil;
import flixel.math.FlxMath;
import funkin.options.Options;
import funkin.options.OptionsMenu;
import funkin.backend.chart.Chart;
import funkin.backend.MusicBeatGroup;
import funkin.backend.utils.AudioAnalyzer;
import funkin.editors.ui.UIState;
import funkin.savedata.FunkinSave;
import funkin.game.HealthIcon;
import funkin.game.PlayState;
import funkin.menus.ModSwitchMenu;
import haxe.Json;
import openfl.ui.MouseCursor;
import openfl.ui.Mouse;
import VCSongText;
using StringTools;

class SongItem extends FlxSprite {
	public var song:Dynamic;
	public var text:Dynamic;
	public var icon:HealthIcon;
	public var back:FlxSprite;
	public var selectedBack:FlxSprite;
	public var port:String;
	public var loadingScreen:String = "default";
	public var selected:Bool = false;

	public var gmAlt:SongItem;
	public var showAlt:Bool = false;

	public var skipLerp = false;

	override public function update(elapsed:Float) {
		super.update(elapsed);
		text.update(elapsed);
		if (icon != null) icon.update(elapsed);
		back.update(elapsed);
		selectedBack.update(elapsed);
		if (gmAlt != null) gmAlt.update(elapsed);
	}
	override public function draw() {
		if (gmAlt != null) {
			gmAlt.y = y;
			gmAlt.selected = selected;
			gmAlt.draw();
		}

		text.scale.set(0.6, 0.6); text.updateHitbox();
		back.scale.set(0.7, 0.7); back.updateHitbox();
		selectedBack.scale.set(0.7, 0.7); selectedBack.updateHitbox();

		if (icon != null) {
			icon.scale.y = icon.scale.x = CoolUtil.fpsLerp(icon.scale.x, 0.7, skipLerp ? 1.0 : 0.06);
			icon.updateHitbox();
		}


		text.x = x - 36;
		text.y = y + 5;
		if (icon != null) {
			icon.x = -36 + x - icon.width;
			icon.y = y + ((back.height/2) - (icon.height/2));
		}

		back.x = x - 150;
		back.y = y;

		selectedBack.alpha = CoolUtil.fpsLerp(selectedBack.alpha, selected ? 1.0 : 0.0, skipLerp ? 1.0 : 0.1);
		back.alpha = CoolUtil.fpsLerp(back.alpha, selected ? 0.0 : 1.0, skipLerp ? 1.0 : 0.1);
		selectedBack.y = y + ((back.height/2) - (selectedBack.height/2));
		selectedBack.x = Math.min(-50, x);

		back.draw();
		selectedBack.draw();
		text.draw();
		if (icon != null) icon.draw();

		skipLerp = false;

	}
	override public function destroy() {
		back.destroy();
		selectedBack.destroy();
		text.destroy();
		if (icon != null) icon.destroy();
		super.destroy();
		if (gmAlt != null) gmAlt.destroy();
	}
}

//list of all metadata
var songList = [];
var songCatData = [];
//list of text objects
var songItems = [];
//group of currently shown text objects
var songGroup:MusicBeatGroup;
var iconGroup:MusicBeatGroup;

var categories = ["" => []];
var catList:Array<String> = [];
var currentCategory:Int = 0;
var selectingCategory:Bool = true;
var categoryGroup:MusicBeatGroup;

static var lastCategory = -1;

var audioAnalyzer:AudioAnalyzer;
var audioBars = [];
var bg:FlxSprite;
var songs = [];
var curSelected:Int = 0;
var curDifficulty:Int = 0;
var canSelect:Bool = false;
var songInstPlaying:Bool = true;
var autoplayElapsed:Float = 0;
var curPlayingInst:String = null;
var __coopMode:Bool = false;
var __opponentMode:Bool = false;
var inputLock:Float = 0.25;
var enableMouseSongHover:Bool = true;
var restoringSongSelectorOnCreate:Bool = false;
var modSwitchOpen:Bool = false;
var pendingInstPreview:Bool = false;
var pendingInstPreviewTimer:Float = 0;
var instPreviewDelay:Float = 1.1;
var difficultySpriteAvailable:Bool = true;

function create() {
	categories.clear();
	//var freeplaySongs = Json.parse(Assets.getText(Paths.getPath("data/freeplaySongs.json")));

	for (lib in Paths.assetsTree.libraries) {
		if (lib.exists(Paths.getPath("data/freeplaySongs.json"), "TEXT")) {
			var freeplaySongs = Json.parse(lib.getText(Paths.getPath("data/freeplaySongs.json")));
			loadFreeplaySongsJson(freeplaySongs);
		}
	}	

	buildPortFreeState();
}

function loadFreeplaySongsJson(freeplaySongs) {
	for (cat in freeplaySongs.categories) {
		for (song in cat.songs) {
			songList.push(Chart.loadChartMeta(song.name, "normal", true));
			songCatData.push(song);

			if (!categories.exists(cat.name)) {
				categories.set(cat.name, []);
				catList.push(cat.name);
			}

			categories.get(cat.name).push(songList.length-1);
		}
	}
}

var defaultSong = '
{
	"composer": "",
	"charter": "",
	"originalComposer": "",
	"startTime": 0,
	"songFont": "dumbnerd.ttf",
	"songFontSize": 128,
	"infoFontSize": 24,
	"outerBorderTop": "#000000",
	"outerBorderBot": "#000000",
	"midBorderTop": "#c735ff",
	"midBorderBot": "#6414ea",
	"innerBorderTop": "#3f3f3f",
	"innerBorderBot": "#121617"
}';

var curScroll:Float = 0.0;

var dotsTop = null;
var dotsBottom = null;

var backButton = null;
var settingsButton = null;

var lastLoadedBGPort = "";
var bgSprite = null;
var emptyBGSprite = null;
var bgFade = null;
var bgFadeShader = null;
var bgFadeValue = 1;

var lastDiffLoaded = "";
var difficultySprite = null;
var diffArrowL = null;
var diffArrowR = null;
var difficultyText = null;

public static var SONG_SPEED = 1.0;
var selectedSongSpeed = 1;
var speedText = null;
var speedArrowL = null;
var speedArrowR = null;
var speedNameText = null;

var freeplayText = null;
var freeplayInfoText = null;

var highscoreNameText = null;
var highscoreTotalText = null;
var highscoreInfoText = null;

var currentHighscoreData = null;
var targetScore = ["", "", "", "", "", ""];
var currentScore = ["", "", "", "", "", ""];
var scoreTmr = 0.0;
var scoreIndex = 0;

function buildPortFreeState() {
	trace("PortFreeState: postCreate");
	FlxG.camera.scroll.set(0, 0);
	FlxG.camera.zoom = 1;
	FlxG.camera.angle = 0;

	if (lastCategory != -1) {
		currentCategory = lastCategory;
		selectingCategory = false;
		restoringSongSelectorOnCreate = true;
	}

	if (FlxG.sound.music == null || !FlxG.sound.music.playing) CoolUtil.playMenuSong();

	bg = new FlxSprite(0, 0);
	bg.loadGraphic(Paths.image('menus/freeplay/BG'));
	bg.setGraphicSize(1280); bg.updateHitbox();
	add(bg);

	var totalBars = 64;
	for (i in 0...totalBars) {
		var spr = new FlxSprite(((FlxG.width/totalBars)+5) * i, FlxG.height);
		spr.makeGraphic(1,1);
		spr.setGraphicSize((FlxG.width/totalBars)-5, 1);
		spr.updateHitbox();
		spr.scrollFactor.set();
		audioBars.push(spr);
		add(spr);
	}

	////////////////////////////////////////

	bgFade = new FlxSprite(0, 156);
	bgFade.loadGraphic(Paths.image('menus/freeplay/bgfade')); add(bgFade);
	bgFade.scale.set(1280/1920,1280/1920); bgFade.updateHitbox();
	bgFade.x = 1280-bgFade.width;
	bgFade.shader = bgFadeShader = new CustomShader("BGFade");

	bgSprite = new FlxSprite();
	//bgSprite.loadGraphic(Paths.image("menus/freeplay/bgs/Wiik1"));
	bgSprite.alpha = 0.001;
	add(bgSprite);

	emptyBGSprite = new FlxSprite();
	emptyBGSprite.makeGraphic(1,1,0xFF000000);
	emptyBGSprite.alpha = 0.001;
	add(emptyBGSprite);

	bgFadeShader.bg = emptyBGSprite.graphic.bitmap;
	bgFadeShader.prevBG = emptyBGSprite.graphic.bitmap;

	/////////////////////////////////////

	dotsTop = new FlxSprite();
	dotsTop.loadGraphic(Paths.image('menus/freeplay/dot_up')); add(dotsTop);
	dotsTop.setGraphicSize(1280); dotsTop.updateHitbox();

	dotsBottom = new FlxSprite();
	dotsBottom.loadGraphic(Paths.image('menus/freeplay/dot_down')); add(dotsBottom);
	dotsBottom.setGraphicSize(1280); dotsBottom.updateHitbox();

	///////////////////////////////////////////

	freeplayText = new VCSongText(0, -5, 0, "FREEPLAY");
	freeplayText.size = 64;
	freeplayText.border1Size = 0;
	freeplayText.border2Size = 5;
	freeplayText.borderIterations = 8;
	freeplayText.border2Color = 0xFF000000;
	freeplayText.font = Paths.font("vcr.ttf");

	freeplayText.x = 1280 - (freeplayText.width+5);
	add(freeplayText);

	freeplayInfoText = new VCSongText(150, 5, 0, "- LEFT and RIGHT to change difficulty | SHIFT + LEFT and RIGHT to change song speed\n- TAB to open mod selector");
	freeplayInfoText.size = 16;
	freeplayInfoText.border1Size = 0;
	freeplayInfoText.border2Size = 2;
	freeplayInfoText.borderIterations = 8;
	freeplayInfoText.border2Color = 0xFF000000;
	freeplayInfoText.font = Paths.font("vcr.ttf");
	add(freeplayInfoText);

	backButton = new FlxSprite(5, 0);
	backButton.loadGraphic(Paths.image('menus/freeplay/back_button'));
	backButton.scale.set(0.7,0.7); backButton.updateHitbox();
	add(backButton); backButton.antialiasing = true;

	settingsButton = new FlxSprite(5, 0 + backButton.height);
	settingsButton.loadGraphic(Paths.image('menus/freeplay/config_button'));
	settingsButton.scale.set(0.7,0.7); settingsButton.updateHitbox();
	add(settingsButton); settingsButton.antialiasing = true;

	highscoreTotalText = new VCSongText(0, 0, 0, "000000");
	highscoreTotalText.border1Size = 0;
	highscoreTotalText.border2Size = 4;
	highscoreTotalText.borderIterations = 8;
	highscoreTotalText.border2Color = 0xFF000000;
	highscoreTotalText.font = Paths.font("digitalix.ttf");
	highscoreTotalText.size = 51;
	add(highscoreTotalText);
	highscoreTotalText.x = 1280 - highscoreTotalText.width;
	highscoreTotalText.y = 720 - highscoreTotalText.height;

	highscoreTotalText.shader = new CustomShader("FreeplayScoreText");

	highscoreNameText = new VCSongText(0, 0, 0, "HIGHSCORE");
	highscoreNameText.color = 0xFFFFFFFF;
	highscoreNameText.border1Size = 0;
	highscoreNameText.border2Size = 5;
	highscoreNameText.borderIterations = 8;
	highscoreNameText.border2Color = 0xFF000000;
	highscoreNameText.font = Paths.font("digitalix.ttf");
	highscoreNameText.size = 25;
	highscoreNameText.scale.set(0.72, 0.72); highscoreNameText.updateHitbox();
	add(highscoreNameText);

	highscoreNameText.x = 1280 - highscoreNameText.width;
	highscoreNameText.y = highscoreTotalText.y - highscoreNameText.height;
	highscoreNameText.y += 10;


	highscoreInfoText = new VCSongText(25, 568, 0, "[asdhjk]");
	highscoreInfoText.color = 0xFF6d4e80;
	highscoreInfoText.border1Size = 0;
	highscoreInfoText.border2Size = 5;
	highscoreInfoText.borderIterations = 8;
	highscoreInfoText.border2Color = 0xFF000000;
	highscoreInfoText.font = Paths.font("digitalix.ttf");
	highscoreInfoText.size = 25;
	highscoreInfoText.scale.set(0.72, 0.72); highscoreInfoText.updateHitbox();
	add(highscoreInfoText);
	highscoreInfoText.x = 1280 - highscoreInfoText.width;

	////////////////////////////////////////////

	songGroup = new MusicBeatGroup();
	insert(999,songGroup);

	categoryGroup = new MusicBeatGroup();
	insert(999,categoryGroup);

	function createSongItem(index, songName, songIcon, metaData, port, loadingScreen, alt) {
		var data = null;
		if (Assets.exists("songs/"+songName+"/credits"+alt+".json")) {
			data = Json.parse(Assets.getText("songs/"+songName+"/credits"+alt+".json"));
		} else {
			data = Json.parse(defaultSong);
		}

		var songText = createSongText(songName, data.songFontSize, 16, data);
		
		songText.ID = index;
		var icon:HealthIcon = new HealthIcon(songIcon);
		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.image("menus/freeplay/square_song"));
		bg.scale.set(0.9, 0.9); bg.updateHitbox();

		var selectedBG:FlxSprite = new FlxSprite();
		selectedBG.loadGraphic(Paths.image("menus/freeplay/square_song_selected"));
		selectedBG.scale.set(0.9, 0.9); selectedBG.updateHitbox();
		selectedBG.alpha = 0;

		songText.scale.set(0.6, 0.6);
		songText.updateHitbox();
		songText.centerOffsets();

		if (songText.width > 650) {
			songText.setGraphicSize(650);
			songText.updateHitbox();
			songText.centerOffsets();
		}

		var songItem = new SongItem();
		songItem.ID = index;
		songItem.song = metaData;
		songItem.text = songText;
		songItem.icon = icon;
		songItem.back = bg;
		songItem.selectedBack = selectedBG;
		songItem.port = port;
		if (loadingScreen != null) songItem.loadingScreen = loadingScreen;
		return songItem;
	}

	for (i in 0...songList.length)
	{
		var songItem = createSongItem(i, songList[i].displayName, songList[i].icon, songList[i], songCatData[i].port, songCatData[i].loadingScreen, "");

		if (songList[i].displayName == "Final Destination") {
			songItem.gmAlt = createSongItem(i, songList[i].displayName, "VoiidGodShagXMatt-icons", songList[i], "FDGOD", "default", "-god");
			songItem.gmAlt.x = -1280;
		}

		songItems.push(songItem);
	}

	//////////////////////////

	difficultySprite = new FlxSprite(0, 720);
	difficultySprite.loadGraphic(Paths.image("menus/freeplay/difficulties/voiid"));
	difficultySprite.scale.set(0.7, 0.7); difficultySprite.updateHitbox();
	difficultySprite.antialiasing = true;
	insert(999, difficultySprite);
	difficultySprite.y -= difficultySprite.height;
	difficultySprite.x = 25;

	difficultyText = new VCSongText(25, difficultySprite.y-24, 0, "DIFFICULTY");
	difficultyText.color = 0xFF6d4e80;
	difficultyText.border1Size = 0;
	difficultyText.border2Size = 5;
	difficultyText.borderIterations = 8;
	difficultyText.border2Color = 0xFF000000;
	difficultyText.font = Paths.font("digitalix.ttf");
	difficultyText.size = 25;
	difficultyText.scale.set(0.72, 0.72); difficultyText.updateHitbox();
	insert(999, difficultyText);

	difficultyText.x = difficultySprite.x + (difficultySprite.width/2) - (difficultyText.width/2);

	diffArrowL = new FlxSprite(0,0);
	diffArrowL.loadGraphic(Paths.image("menus/freeplay/left_arrow"));
	diffArrowL.antialiasing = true;
	diffArrowL.scale.set(0.85, 0.85); diffArrowL.updateHitbox();
	diffArrowL.x = difficultySprite.x - (diffArrowL.width/2);
	diffArrowL.y = difficultySprite.y + (difficultySprite.height/2) - (diffArrowL.height/2);
	insert(999, diffArrowL);

	diffArrowR = new FlxSprite(0,0);
	diffArrowR.loadGraphic(Paths.image("menus/freeplay/left_arrow"));
	diffArrowR.antialiasing = true;
	diffArrowR.flipX = true;
	diffArrowR.scale.set(0.85, 0.85); diffArrowR.updateHitbox();
	diffArrowR.x = (difficultySprite.width + difficultySprite.x) - (diffArrowR.width/2);
	diffArrowR.y = difficultySprite.y + (difficultySprite.height/2) - (diffArrowR.height/2);
	insert(999, diffArrowR);

	////////////////////////////////////

	speedNameText = new VCSongText(50+200, difficultyText.y, 0, "SONG SPEED");
	speedNameText.color = 0xFF6d4e80;
	speedNameText.border1Size = 0;
	speedNameText.border2Size = 5;
	speedNameText.borderIterations = 8;
	speedNameText.border2Color = 0xFF000000;
	speedNameText.font = Paths.font("digitalix.ttf");
	speedNameText.size = 25;
	speedNameText.scale.set(0.72, 0.72); speedNameText.updateHitbox();
	insert(999, speedNameText);


	speedText = new VCSongText(50, 0, 0, "1.0");
	speedText.color = 0xffffffff;
	speedText.border1Size = 0;
	speedText.border2Size = 5;
	speedText.borderIterations = 8;
	speedText.border2Color = 0xFF000000;
	speedText.font = Paths.font("digitalix.ttf");
	speedText.size = 25;
	speedText.scale.set(1, 1); speedText.updateHitbox();
	insert(999, speedText);

	speedText.x = 215 + difficultySprite.x + (difficultySprite.width/2) - (speedText.width/2);
	speedText.y = difficultySprite.y + (difficultySprite.height/2) - (speedText.height/2);
	speedNameText.x = speedText.x + (speedText.width/2) - (speedNameText.width/2);

	speedArrowL = new FlxSprite(0,0);
	speedArrowL.loadGraphic(Paths.image("menus/freeplay/left_arrow"));
	speedArrowL.antialiasing = true;
	speedArrowL.scale.set(0.85, 0.85); speedArrowL.updateHitbox();
	speedArrowL.x = -32 + speedText.x - (speedArrowL.width/2);
	speedArrowL.y = speedText.y + (speedText.height/2) - (speedArrowL.height/2);
	insert(999, speedArrowL);

	speedArrowR = new FlxSprite(0,0);
	speedArrowR.loadGraphic(Paths.image("menus/freeplay/left_arrow"));
	speedArrowR.antialiasing = true;
	speedArrowR.flipX = true;
	speedArrowR.scale.set(0.85, 0.85); speedArrowR.updateHitbox();
	speedArrowR.x = 32 + (speedText.width + speedText.x) - (speedArrowR.width/2);
	speedArrowR.y = speedText.y + (speedText.height/2) - (speedArrowR.height/2);
	insert(999, speedArrowR);



	///////////////////////////////////

	
	for (i => cat in catList) {
		var data = null;
		if (Assets.exists("data/freeplayCategories/"+cat+".json")) {
			data = Json.parse(Assets.getText("data/freeplayCategories/"+cat+".json"));
		} else {
			data = Json.parse(defaultSong);
		}

		var songText = createSongText(cat, data.songFontSize, 16, data);
		songText.ID = i;

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.image("menus/freeplay/square_song"));
		bg.scale.set(0.9, 0.9); bg.updateHitbox();

		var selectedBG:FlxSprite = new FlxSprite();
		selectedBG.loadGraphic(Paths.image("menus/freeplay/square_song_selected"));
		selectedBG.scale.set(0.9, 0.9); selectedBG.updateHitbox();
		selectedBG.alpha = 0;

		songText.scale.set(0.6, 0.6);
		songText.updateHitbox();
		songText.centerOffsets();
		if (songText.width > 650) {
			songText.setGraphicSize(650);
			songText.updateHitbox();
			songText.centerOffsets();
		}

		var songItem = new SongItem();
		songItem.ID = i;
		songItem.text = songText;
		songItem.back = bg;
		songItem.selectedBack = selectedBG;
		songItem.port = "";
		
		categoryGroup.add(songItem);
	}

	loadCategory(catList[currentCategory]);

	for(k=>s in songs) {
		if (s.name == Options.freeplayLastSong) {
			curSelected = k;
		}
	}
	if (songs[curSelected] != null) {
		for(k=>diff in songs[curSelected].difficulties) {
			if (diff == Options.freeplayLastDifficulty) {
				curDifficulty = k;
			}
		}
	}
	curScroll = curSelected;
	if (curScroll < 1) curScroll = 1;
	if (curScroll > songGroup.members.length-2) curScroll = songGroup.members.length-2;
	changeDiff(0, true);
	updateSongGroup(curSelected);
	playCurrentInstPreview();
	if (restoringSongSelectorOnCreate) {
		prepareSongIntroPositions();
		firstFrame = false;
	} else {
		// Only snap on a fresh state creation. Normal category/song navigation keeps its slide animation.
		snapMenuPositions();
	}
}

function loadCategory(name:String) {
	for (song in songGroup.members) {
		songGroup.remove(song);
	}
	songGroup.clear();
	songs = [];

	lastCategory = currentCategory;

	if (categories.exists(name)) {
		var list = categories.get(name);
		for (id in list) {
			songs.push(songList[id]);
			songGroup.add(songItems[id]);
			//songItems[id].x = 1280;
			songItems[id].selected = false;
		}
	}
	curSelected = FlxMath.wrap(curSelected, 0, songs.length-1);
	curScroll = curSelected;
	if (curScroll < 1) curScroll = 1;
	if (curScroll > songGroup.members.length-2) curScroll = songGroup.members.length-2;
	changeDiff(0, true);
	updateSongGroup(curSelected);
}

function playCurrentInstPreview() {
	if (songs == null || songs.length <= 0 || songs[curSelected] == null) return;

	var meta = songs[curSelected];
	var nextInst = meta.name + ":" + selectedSongSpeed;
	if (curPlayingInst == nextInst && FlxG.sound.music != null && FlxG.sound.music.playing) return;

	curPlayingInst = nextInst;
	if (FlxG.sound.music != null) FlxG.sound.music.stop();
	FlxG.sound.music = FlxG.sound.load(Paths.inst(meta.name));
	if (FlxG.sound.music != null) {
		FlxG.sound.music.play();
		FlxG.sound.music.pitch = selectedSongSpeed;
		Conductor.changeBPM(meta.bpm, meta.beatsPerMeasure, meta.stepsPerBeat);
		audioAnalyzer = new AudioAnalyzer(FlxG.sound.music);
	}
}

function queueInstPreview(?delay:Float = 0.55) {
	pendingInstPreview = true;
	pendingInstPreviewTimer = delay;
}

function changeSelection(change:Int = 0, ?force:Bool = false) {
	if (songs == null || songs.length <= 0) return;
	if (change == 0 && !force) return;

	curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
	curScroll = curSelected;
	if (curScroll < 1) curScroll = 1;
	if (curScroll > songGroup.members.length - 2) curScroll = songGroup.members.length - 2;
	if (change != 0) CoolUtil.playMenuSFX(0);

	changeDiff(0, true);
	updateSongGroup(curSelected);
	queueInstPreview(instPreviewDelay);
}

function changeDiff(change:Int = 0, ?force:Bool = false) {
	if (songs == null || songs.length <= 0 || songs[curSelected] == null) return;
	var diffs = songs[curSelected].difficulties;
	if (diffs == null || diffs.length <= 0) return;
	if (change == 0 && !force) {
		refreshDifficultyVisual(curDifficulty);
		updateScores(curDifficulty);
		return;
	}

	curDifficulty = FlxMath.wrap(curDifficulty + change, 0, diffs.length - 1);
	if (change != 0) CoolUtil.playMenuSFX(0);
	refreshDifficultyVisual(curDifficulty);
	updateScores(curDifficulty);
}

function select() {
	if (songs == null || songs.length <= 0 || songs[curSelected] == null) return;

	var song = songs[curSelected];
	var diff = (song.difficulties == null || song.difficulties.length <= 0) ? "normal" : song.difficulties[curDifficulty];
	Options.freeplayLastSong = song.name;
	Options.freeplayLastDifficulty = diff;
	PlayState.loadSong(song.name, diff, __opponentMode, __coopMode);
	FlxG.switchState(new PlayState());
}

function openConfigMenu() {
	CoolUtil.playMenuSFX(1, 0.7);
	FlxG.switchState(new OptionsMenu(function(_) {
		FlxG.switchState(new ModState("PortFreeState"));
	}));
}

function openModSwitchSelector() {
	trace("PortFreeState: opening ModSwitchMenu");
	CoolUtil.playMenuSFX(1, 0.7);
	modSwitchOpen = true;
	persistentUpdate = false;
	Reflect.setField(FlxG.save.data, "voiidReturnToPortFreeplayFromModSwitch", true);

	var menu = new ModSwitchMenu();
	menu.closeCallback = function() {
		modSwitchOpen = false;
		persistentUpdate = true;
		inputLock = 0.25;
	};
	openSubState(menu);
	inputLock = 0.25;
}

var songXPos = 2000;
var reloadCategory = false;
var firstFrame = true;

function getMinSongIndex() {return Math.max(0, curSelected-3);}
function getMaxSongIndex() {return songGroup == null ? 0 : Math.min(songGroup.members.length, curSelected+3);}

function snapMenuPositions() {
	if (songGroup != null) {
		songXPos = selectingCategory ? -1280 : 0;
		for (i in 0...songGroup.members.length) {
			var t = songGroup.members[i];
			if (t == null) continue;

			var p = (curScroll - i) - 2;
			if (p < -3) p = -3;
			if (p > -1) p = -1;

			var targetY = (-p * 136) + 38;
			var targetX = 150.0;
			if (Math.abs(curScroll - i) > 1) targetX = -1280;
			else if (curSelected - i == 0) targetX = 200;

			t.x = songXPos + targetX;
			t.y = targetY;
			t.selected = curSelected - i == 0;
		}
	}

	if (categoryGroup != null) {
		for (i in 0...categoryGroup.members.length) {
			var t = categoryGroup.members[i];
			if (t == null) continue;

			var p = (currentCategory - i) - 2;
			if (p < -3) p = -3;
			if (p > -1) p = -1;

			var targetY = (-p * 136) + 38;
			var targetX = 150.0;
			if (Math.abs(currentCategory - i) > 1) targetX = -1280;
			else if (currentCategory - i == 0) targetX = 200;
			if (!selectingCategory) targetX -= 1280;

			t.x = targetX;
			t.y = targetY;
			t.selected = currentCategory - i == 0;
		}
	}

	if (bgFade != null) bgFade.x = (1280 - bgFade.width) - songXPos;
}

function prepareSongIntroPositions() {
	songXPos = 2000;

	if (songGroup != null) {
		for (i in 0...songGroup.members.length) {
			var t = songGroup.members[i];
			if (t == null) continue;

			var p = (curScroll - i) - 2;
			if (p < -3) p = -3;
			if (p > -1) p = -1;

			var targetY = (-p * 136) + 38;
			var targetX = 150.0;
			if (Math.abs(curScroll - i) > 1) targetX = -1280;
			else if (curSelected - i == 0) targetX = 200;

			t.x = songXPos + targetX;
			t.y = targetY;
			t.selected = curSelected - i == 0;
		}
	}

	if (categoryGroup != null) {
		for (i in 0...categoryGroup.members.length) {
			var t = categoryGroup.members[i];
			if (t == null) continue;

			var p = (currentCategory - i) - 2;
			if (p < -3) p = -3;
			if (p > -1) p = -1;

			var targetY = (-p * 136) + 38;
			var targetX = 150.0;
			if (Math.abs(currentCategory - i) > 1) targetX = -1280;
			else if (currentCategory - i == 0) targetX = 200;

			t.x = targetX - 1280;
			t.y = targetY;
			t.selected = currentCategory - i == 0;
		}
	}

	if (bgFade != null) bgFade.x = (1280 - bgFade.width) - songXPos;
}

function postUpdate(elapsed) {
	updateSongInfoVisibility();

	if (pendingInstPreview) {
		pendingInstPreviewTimer -= elapsed;
		if (pendingInstPreviewTimer <= 0) {
			pendingInstPreview = false;
			playCurrentInstPreview();
		}
	}

	var skipLerp = firstFrame && !selectingCategory;

	songXPos = CoolUtil.fpsLerp(songXPos, selectingCategory ? -1280 : 0, skipLerp ? 60.0 : 0.07);
	if (bgFade != null) bgFade.x = (1280-bgFade.width)-songXPos;

	bgFadeValue = CoolUtil.fpsLerp(bgFadeValue, 0, 0.05);
	if (bgFadeShader != null) bgFadeShader.fade = bgFadeValue;

	for (i in getMinSongIndex()...getMaxSongIndex()) {
		var p = (curScroll - i) - 2;
		if (p < -3) p = -3;
		if (p > -1) p = -1;

		var t = songGroup.members[i];
		if (t == null) continue;

		var targetY = (-p * 136) + 38;
		var targetX = 150.0;
		var lerpSpeed = 0.2;
		if (Math.abs(curScroll - i) > 1) {
			targetX = -1280;
			lerpSpeed = 0.05;
		} else if (curSelected - i == 0) {
			targetX = 200;
		}

		var altTargetX = -1280;
		if (curSelected - i == 0 && (lastDiffLoaded.toLowerCase() == "god" || lastDiffLoaded.toLowerCase() == "god mania")) {
			t.showAlt = true;
			targetX = -1280;
			altTargetX = 200;
		} else {
			t.showAlt = false;
		}

		if (t.gmAlt != null) {
			t.gmAlt.x = CoolUtil.fpsLerp(t.gmAlt.x, songXPos + altTargetX, skipLerp ? 60.0 : lerpSpeed);
		}

		t.y = CoolUtil.fpsLerp(t.y, targetY, skipLerp ? 60.0 : 0.12);
		t.x = CoolUtil.fpsLerp(t.x, songXPos + targetX, skipLerp ? 60.0 : lerpSpeed);
		t.selected = curSelected - i == 0;

		

	}

	if (categoryGroup != null) {
		for (i in 0...categoryGroup.members.length) {
			var p = (currentCategory - i) - 2;
			if (p < -3) p = -3;
			if (p > -1) p = -1;

			var t = categoryGroup.members[i];
			if (t == null) continue;

			var targetY = (-p * 136) + 38;
			var targetX = 150.0;
			var lerpSpeed = 0.2;
			if (Math.abs(currentCategory - i) > 1) {
				targetX = -1280;
				lerpSpeed = 0.05;
			} else if (currentCategory - i == 0) {
				targetX = 200;
			}

			if (!selectingCategory) {
				targetX -= 1280;
			}

			
			t.y = CoolUtil.fpsLerp(t.y, targetY, skipLerp ? 60.0 : 0.12);
			t.x = CoolUtil.fpsLerp(t.x, targetX, skipLerp ? 60.0 : lerpSpeed);
			t.selected = currentCategory - i == 0;
		}
	}

	if (scoreIndex < targetScore.length) {
		scoreTmr += elapsed;
		if (scoreTmr > 0.05) {
			scoreTmr = 0;

			currentScore[scoreIndex] = targetScore[scoreIndex];

			var str = "";
			for (i in 0...currentScore.length) {
				str = str + currentScore[i];
			}

			if (highscoreTotalText != null) {
				highscoreTotalText.text = str;
				highscoreTotalText.x = 1280 - highscoreTotalText.width;
			}
			//var str = highscoreTotalText.text;

			//str[scoreIndex] = targetScore[scoreIndex];

			//highscoreTotalText.text = str;

			scoreIndex++;
		}
	}

	

	if (curPlayingInst != lastPlayedInst) {
		audioAnalyzer = null;
		if (FlxG.sound.music != null && FlxG.sound.music.playing && songs != null && songs.length > 0 && songs[curSelected] != null) {
			audioAnalyzer = new AudioAnalyzer(FlxG.sound.music);
			lastPlayedInst = curPlayingInst;
			var meta = songs[curSelected]; //update the bpm
			lastPlayedSongInst = meta.displayName;
			Conductor.changeBPM(meta.bpm, meta.beatsPerMeasure, meta.stepsPerBeat);
		}
	}
	if (FlxG.sound.music != null && FlxG.sound.music.playing) {
		FlxG.sound.music.pitch = selectedSongSpeed;
	}


	var l = 0;
	var n = 0;
	var time = (FlxG.sound.music != null) ? Math.floor(FlxG.sound.music.time/10)*10 : 0;
	for (i in 0...audioBars.length) {
		var spr = audioBars[i];
		
		n += 10 / audioBars.length;
		var v = audioAnalyzer != null ? audioAnalyzer.analyze(time + l, time + n) : 0;
		spr.scale.y = CoolUtil.fpsLerp(spr.scale.y, v*250, 0.15);
		spr.y = FlxG.height-spr.scale.y;
		spr.updateHitbox();
		l = n;
	}
		//var shit = Math.log(1 + (audioAnalyzer.analyze(Conductor.songPosition, Conductor.songPosition+1))) / Math.log(10);
		//var targetZoom = 1.0 + (shit);
		//FlxG.camera.zoom = CoolUtil.fpsLerp(FlxG.camera.zoom, targetZoom, 0.2);
		//trace(Conductor.songPosition + " : " + audioAnalyzer.analyze(Conductor.songPosition, Conductor.songPosition+1));

	if (reloadCategory) {
		loadCategory(catList[currentCategory]);
		reloadCategory = false;
	}

	firstFrame = false;
}

var lastPlayedInst:String = null;
var lastPlayedSongInst:String = "";

var hoveringThisFrame = false;

function updateSongInfoVisibility() {
	var showSongInfo = !selectingCategory;

	if (difficultySprite != null) difficultySprite.visible = showSongInfo && difficultySpriteAvailable;
	if (difficultyText != null) difficultyText.visible = showSongInfo;
	if (diffArrowL != null) diffArrowL.visible = showSongInfo && songs != null && songs.length > 0 && songs[curSelected] != null && songs[curSelected].difficulties != null && songs[curSelected].difficulties.length > 1;
	if (diffArrowR != null) diffArrowR.visible = diffArrowL != null && diffArrowL.visible;

	if (speedNameText != null) speedNameText.visible = showSongInfo;
	if (speedText != null) speedText.visible = showSongInfo;
	if (speedArrowL != null) speedArrowL.visible = showSongInfo;
	if (speedArrowR != null) speedArrowR.visible = showSongInfo;

	if (highscoreNameText != null) highscoreNameText.visible = showSongInfo;
	if (highscoreTotalText != null) highscoreTotalText.visible = showSongInfo;
	if (highscoreInfoText != null) highscoreInfoText.visible = showSongInfo;
}

function update(elapsed) {
	if (modSwitchOpen || subState != null) {
		controls.ACCEPT = false;
		controls.BACK = false;
		return;
	}

	hoveringThisFrame = false;
	if (inputLock > 0) inputLock -= elapsed;

	if (songGroup == null || categoryGroup == null || catList == null || catList.length <= 0) {
		controls.ACCEPT = false;
		controls.BACK = false;
		return;
	}

	var pressedBack = controls.getJustPressed("back") || FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.B || FlxG.mouse.justPressedRight;
	var pressedAccept = controls.getJustPressed("accept") || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE;
	var pressedUp = controls.getJustPressed("up") || FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W;
	var pressedDown = controls.getJustPressed("down") || FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S;
	var pressedLeft = controls.getJustPressed("left") || FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A;
	var pressedRight = controls.getJustPressed("right") || FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D;

	var actualBACK = inputLock <= 0 && pressedBack;
	controls.BACK = false;
	var actualACCEPT = inputLock <= 0 && pressedAccept;
	controls.ACCEPT = false;

	if (inputLock <= 0 && FlxG.keys.justPressed.TAB) {
		openModSwitchSelector();
		return;
	}

	canSelect = false;
	if (FlxG.mouse.justMoved) FlxG.mouse.visible = true;

	if (!selectingCategory) {
		changeSelection((pressedUp ? -1 : 0) + (pressedDown ? 1 : 0) - FlxG.mouse.wheel);
		if (FlxG.keys.pressed.SHIFT)
			changeSongSpeed((pressedLeft ? -0.1 : 0) + (pressedRight ? 0.1 : 0));
		else
			changeDiff((pressedLeft ? -1 : 0) + (pressedRight ? 1 : 0));

		if (enableMouseSongHover) for (i in getMinSongIndex()...getMaxSongIndex()) {
			var t = songGroup.members[i];

			if (t == null || t.back == null || t.text == null) continue;

			if (isMouseOverSprite(t.back) || isMouseOverSprite(t.text)) {

				hoveringThisFrame = true;
				if (FlxG.mouse.justPressed) {
					if (curSelected != i) {
						curSelected = i;
						var lastCurScroll = curScroll;
						changeSelection(0, true);
						curScroll = lastCurScroll;
					} else {
						actualACCEPT = true;
					}
				} 
			}
		}

		if (isClicked(diffArrowL)) changeDiff(-1);
		if (isClicked(diffArrowR)) changeDiff(1);
		if (isClicked(speedArrowL)) changeSongSpeed(-0.1);
		if (isClicked(speedArrowR)) changeSongSpeed(0.1);

	} else {
		var change = (pressedUp ? -1 : 0) + (pressedDown ? 1 : 0) - FlxG.mouse.wheel;
		if (change != 0) {
			currentCategory = FlxMath.wrap(currentCategory + change, 0, catList.length-1);
			CoolUtil.playMenuSFX(0, 0.7);
		}

		if (categoryGroup != null) for (i in 0...categoryGroup.members.length) {
			var t = categoryGroup.members[i];
			if (t == null || t.back == null || t.text == null) continue;

			if (isMouseOverSprite(t.back) || isMouseOverSprite(t.text)) {
				hoveringThisFrame = true;
				if (FlxG.mouse.justPressed) {
					if (currentCategory != i) {
						currentCategory = i;
						CoolUtil.playMenuSFX(0, 0.7);
					} else {
						actualACCEPT = true;
					}
				}
			}
		}
	}

	if (isClicked(backButton)) actualBACK = true;
	if (settingsButton != null && isClicked(settingsButton)) {
		openConfigMenu();
		return;
	}

	if (actualBACK) {
		if (selectingCategory) {
			trace("PortFreeState: BACK from categories -> MainMenu");
			CoolUtil.playMenuSFX(2, 0.7);
			Reflect.setField(FlxG.save.data, "voiidReturnToPortFreeplayFromModSwitch", false);
			FlxG.switchState(new MainMenuState());
		} else {
			trace("PortFreeState: BACK from songs -> categories");
			CoolUtil.playMenuSFX(2, 0.7);
			selectingCategory = true;
			songInstPlaying = true;
			lastCategory = -1;
			inputLock = 0.18;
		}
	}
	if (actualACCEPT) {
		if (selectingCategory) {
			trace("PortFreeState: ACCEPT category -> songs: " + catList[currentCategory]);
			CoolUtil.playMenuSFX(1, 0.7);
			selectingCategory = false;
			loadCategory(catList[currentCategory]);
			reloadCategory = false;
			autoplayElapsed = 0;
			songInstPlaying = false;
			inputLock = 0.18;
		} else {
			trace("PortFreeState: ACCEPT song -> PlayState");
			SONG_SPEED = selectedSongSpeed;
			if (songGroup != null && songGroup.members[curSelected] != null) CURRENT_LOADING_SCREEN = songGroup.members[curSelected].loadingScreen;
			select();
		}
	}

	Mouse.cursor = hoveringThisFrame ? MouseCursor.BUTTON : MouseCursor.ARROW;
}
function destroy() {
	Mouse.cursor = MouseCursor.ARROW;
}


function onChangeSelection(e) {
	

	updateSongGroup(e.value);
	curScroll = e.value;
	if (curScroll < 1) curScroll = 1;
	if (songGroup == null) return;
	if (curScroll > songGroup.members.length-2) curScroll = songGroup.members.length-2; 
}
var wasGM = false;
function getDifficultyImagePath(diffName:String):String {
	var cleanDiff = diffName == null ? "" : StringTools.trim(diffName).toLowerCase();
	var compactDiff = StringTools.replace(cleanDiff, " ", "");
	var basePath = "menus/freeplay/difficulties/";

	if (Paths.assetsTree.exists(Paths.getPath("images/" + basePath + cleanDiff + ".png"), "IMAGE") || Assets.exists(Paths.image(basePath + cleanDiff))) return basePath + cleanDiff;
	if (compactDiff != cleanDiff && (Paths.assetsTree.exists(Paths.getPath("images/" + basePath + compactDiff + ".png"), "IMAGE") || Assets.exists(Paths.image(basePath + compactDiff)))) return basePath + compactDiff;
	return null;
}

function reloadDifficultyGraphic(diffName:String) {
	var path = getDifficultyImagePath(diffName);

	if (path != null) {
		difficultySprite.loadGraphic(Paths.image(path));
		difficultySprite.scale.set(0.7, 0.7);
		difficultySprite.updateHitbox();
		difficultySpriteAvailable = true;
		difficultySprite.visible = !selectingCategory;

		diffArrowL.x = difficultySprite.x - (diffArrowL.width/2);
		diffArrowL.y = difficultySprite.y + (difficultySprite.height/2) - (diffArrowL.height/2);
		diffArrowR.x = (difficultySprite.width + difficultySprite.x) - (diffArrowR.width/2);
		diffArrowR.y = difficultySprite.y + (difficultySprite.height/2) - (diffArrowR.height/2);
		difficultyText.x = difficultySprite.x + (difficultySprite.width/2) - (difficultyText.width/2);
	} else {
		trace("PortFreeState: difficulty image not found -> " + diffName);
		difficultySpriteAvailable = false;
		difficultySprite.visible = false;
	}
}

function refreshDifficultyVisual(diffIndex:Int) {
	if (difficultySprite == null) return;

	var diffs = songs[curSelected].difficulties;
	if (diffs == null || diffs.length <= 0) return;
	diffIndex = FlxMath.wrap(diffIndex, 0, diffs.length - 1);

	if (lastDiffLoaded != diffs[diffIndex]) {
		lastDiffLoaded = diffs[diffIndex];
		reloadDifficultyGraphic(lastDiffLoaded);

		var isGod = (lastDiffLoaded.toLowerCase() == "god" || lastDiffLoaded.toLowerCase() == "god mania");
		if (wasGM != isGod) {
			wasGM = isGod;
			autoplayElapsed = 0;
			songInstPlaying = false;
			updateSongGroup(curSelected, isGod);
		}
	}

	updateSongInfoVisibility();
}

function onChangeDiff(e) {
	refreshDifficultyVisual(e.value);

	updateScores(e.value);
}
function updateSongGroup(v, ?doAlt = false) {
	if (doAlt == null) doAlt = false;

	if (songGroup == null) return;
	for (i in 0...songGroup.members.length) {
		var p = (v - i);
		
		var t = songGroup.members[i];
		if (t == null) continue;
		t.active = t.visible = true;
		if (p < -2) {
			t.selected = false;
			t.active = t.visible = false;
			t.x = -1280;
		} else if (p > 2) {
			t.selected = false;
			t.active = t.visible = false;
			t.x = -1280;
		}
	}

	if (songGroup.members[v] == null) return;
	var bgPort = songGroup.members[v].port;
	if (doAlt && songGroup.members[v].gmAlt != null) {
		bgPort = songGroup.members[v].gmAlt.port;
	}
	if (lastLoadedBGPort != bgPort) {
		lastLoadedBGPort = bgPort;
		if (bgFadeShader == null) return;
		bgFadeShader.prevBG = bgFadeShader.bg;
		bgFadeValue = 1;
		if (Assets.exists(Paths.image('freeplayBGs/'+bgPort))) {
			bgSprite.loadGraphic(Paths.image("freeplayBGs/"+bgPort));
			bgFadeShader.bg = bgSprite.graphic.bitmap;
		} else {
			bgFadeShader.bg = emptyBGSprite.graphic.bitmap;
		}
	}
}

function changeSongSpeed(change:Float) {
	if (change == 0) return;

	selectedSongSpeed += change;
	if (selectedSongSpeed < 0.5) selectedSongSpeed = 0.5;
	if (selectedSongSpeed > 2) selectedSongSpeed = 2;
	selectedSongSpeed = FlxMath.roundDecimal(selectedSongSpeed, 2);
	var display = selectedSongSpeed+"";
	if (display.indexOf(".") == -1) display += ".0";
	speedText.text = display;
}

function updateScores(diffValue) {
	currentHighscoreData = FunkinSave.getSongHighscore(songs[curSelected].name, songs[curSelected].difficulties[diffValue]);
	//trace(saveData);

	var str = Std.string(currentHighscoreData.score);
	for (i in 0...targetScore.length) {
		targetScore[i] = "";
	}

	var diff = targetScore.length - str.length;
	for (i in 0...str.length) {
		if (diff > 0) {
			targetScore[i+diff] = str.charAt(i);
		} else {
			targetScore[i] = str.charAt(i);
		}
	}

	while (targetScore.length > currentScore.length) {
		currentScore.insert(0, "");
	}

	for (i in 0...targetScore.length) {
		if (targetScore[i] == "" && targetScore.length-i <= 6) {
			targetScore[i] = "0";
		}
	}
	
	scoreTmr = 0;
	scoreIndex = 0;

	var diffs = songs[curSelected].difficulties;

	var infoText:String = "[ ";
	infoText += diffs[diffValue].toUpperCase() + " - ";
	if (currentHighscoreData.score > 0) {
		infoText += (currentHighscoreData.misses == 0 ? "FC" : "CLEAR") + " - ";
		infoText += getRank(currentHighscoreData.accuracy);
	} else {
		infoText += "NOT CLEARED";
	}

	infoText += " ]";
	highscoreInfoText.text = infoText;
	highscoreInfoText.updateHitbox();
	highscoreInfoText.x = 1280 - highscoreInfoText.width;

	curDifficulty = diffValue;
}
var ranks = [
	[0, "F"],
	[0.5, "E"],
	[0.7, "D"],
	[0.8, "C"],
	[0.85, "B"],
	[0.9, "A"],
	[0.95, "S"],
	[1.0, "S++"]
];

function getRank(acc) {
	var rank = "F";
	for(e in ranks)
		if (e[0] <= acc)
			rank = e[1];

	return rank;
}

function beatHit() {
	if (songGroup != null && (Conductor.bpm < 200 || curBeat % 2 == 0)) {
		for (i in 0...songGroup.members.length) {
			var t = songGroup.members[i];
			if (t == null || t.song == null || t.icon == null) continue;
			if (t.song.displayName == lastPlayedSongInst) {
				t.icon.scale.x = 0.7*1.2;
				t.icon.scale.y = 0.7*1.2;
				if (t.gmAlt != null && t.gmAlt.icon != null) {
					t.gmAlt.icon.scale.x = 0.7*1.2;
					t.gmAlt.icon.scale.y = 0.7*1.2;
				}
			}
		}
	}
	//if (curBeat % 4 == 0) {

	//}

}


function isMouseOverSprite(obj:FlxSprite) {
	if (obj == null) return false;
	if (!obj.visible || !obj.exists) return false;
	var mx = FlxG.mouse.x;
	var my = FlxG.mouse.y;
	return mx >= obj.x && mx <= obj.x + obj.width && my >= obj.y && my <= obj.y + obj.height;
}

function isClicked(obj:FlxSprite) {
	var overlapping = isMouseOverSprite(obj);
	if (overlapping) {
		hoveringThisFrame = true;
	}
	return overlapping && FlxG.mouse.justPressed;
}
