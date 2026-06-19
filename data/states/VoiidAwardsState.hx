import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxTextBorderStyle;
import flixel.util.FlxColor;
import funkin.backend.FunkinText;
import funkin.backend.scripting.ModState;
import lime.utils.Assets;

var awards:Array<Dynamic> = [
	{name: "Wiik 1", desc: "Beat Wiik 1", save: "beat_wiik 1", image: "Wiik1"},
	{name: "Light it Up FC", desc: "Full combo Light It Up", save: "fc_light it up", image: "Wiik1FC"},
	{name: "Ruckus FC", desc: "Full combo Ruckus", save: "fc_ruckus", image: "Wiik1FC"},
	{name: "Target Practice FC", desc: "Full combo Target Practice", save: "fc_target practice", image: "Wiik1FC"},
	{name: "Wiik 2", desc: "Beat Wiik 2", save: "beat_wiik 2", image: "Wiik2"},
	{name: "Burnout FC", desc: "Full combo Burnout", save: "fc_burnout", image: "Wiik2FC"},
	{name: "Sporting FC", desc: "Full combo Sporting", save: "fc_sporting", image: "Wiik2FC"},
	{name: "Boxing Match FC", desc: "Full combo Boxing Match", save: "fc_boxing match", image: "Wiik2FC"},
	{name: "Wiik 3", desc: "Beat Wiik 3", save: "beat_wiik 3", image: "Wiik3"},
	{name: "Fisticuffs FC", desc: "Full combo Fisticuffs", save: "fc_fisticuffs", image: "Wiik3FC"},
	{name: "Blastout FC", desc: "Full combo Blastout", save: "fc_blastout", image: "Wiik3FC"},
	{name: "Immortal FC", desc: "Full combo Immortal", save: "fc_immortal", image: "Wiik3FC"},
	{name: "King Hit FC", desc: "Full combo King Hit", save: "fc_king hit", image: "Wiik3FC"},
	{name: "Wiik 100", desc: "Beat Wiik 100", save: "beat_wiik 100", image: "Wiik100"},
	{name: "Mat FC", desc: "Full combo Mat", save: "fc_mat", image: "Wiik100FC"},
	{name: "Banger FC", desc: "Full combo Banger", save: "fc_banger", image: "Wiik100FC"},
	{name: "Edgy FC", desc: "Full combo Edgy", save: "fc_edgy", image: "Wiik100FC"},
	{name: "Alter Ego FC", desc: "Full combo Alter Ego", save: "fc_alter ego", image: "AlterEgo"},
	{name: "Rejected FC", desc: "Full combo Rejected", save: "fc_rejected", image: "Rejected"}
];

var cards:Array<Dynamic> = [];
var scroll:Float = 0;
var maxScroll:Float = 0;
var percentText:FunkinText;

function create() {
	CoolUtil.playMenuSong();
	FlxG.mouse.visible = true;

	add(fullImage("credits/Credits-BG", 1));
	add(fullImage("main menu/new/DOT_DOWN", 0.5));
	add(fullImage("main menu/new/DOT_UP", 0.5));

	var title = new FunkinText(0, 24, FlxG.width, "AWARDS", 56, true);
	title.alignment = "center";
	title.font = Paths.font("vcr.ttf");
	title.borderStyle = FlxTextBorderStyle.OUTLINE;
	title.borderColor = FlxColor.BLACK;
	add(title);

	for (i in 0...awards.length) {
		var card = makeCard(FlxG.width * 0.5 - 245, 125 + i * 132, awards[i]);
		cards.push(card);
	}

	percentText = new FunkinText(10, FlxG.height - 38, 0, "", 24, true);
	percentText.font = Paths.font("vcr.ttf");
	add(percentText);
	updatePercent();

	maxScroll = Math.max(0, 125 + awards.length * 132 - FlxG.height + 95);
}

function fullImage(path:String, alpha:Float):FlxSprite {
	var spr = new FlxSprite().loadGraphic(Paths.image(path));
	spr.setGraphicSize(FlxG.width);
	spr.updateHitbox();
	spr.screenCenter();
	spr.antialiasing = Options.antialiasing;
	spr.alpha = alpha;
	return spr;
}

function isUnlocked(save:String):Bool {
	return Reflect.field(FlxG.save.data, "voiid_award_" + save) == true;
}

function makeCard(x:Float, y:Float, award:Dynamic):Dynamic {
	var bg = new FlxSprite(x, y).makeGraphic(490, 108, 0xDD000000);
	add(bg);

	var iconPath = "awards/" + award.image;
	if (!Assets.exists(Paths.image(iconPath))) iconPath = "awards/default";
	var icon = new FlxSprite(x + 378, y + 9).loadGraphic(Paths.image(iconPath));
	icon.setGraphicSize(90, 90);
	icon.updateHitbox();
	icon.antialiasing = Options.antialiasing;
	add(icon);

	var name = new FunkinText(x + 18, y + 10, 330, award.name, 32, true);
	name.font = Paths.font("Contb___.ttf");
	add(name);

	var desc = new FunkinText(x + 20, y + 55, 340, award.desc, 18, true);
	desc.font = Paths.font("vcr.ttf");
	desc.alpha = 0.78;
	add(desc);

	var lock = new FunkinText(x + 392, y + 38, 80, "LOCKED", 18, true);
	lock.alignment = "center";
	lock.font = Paths.font("vcr.ttf");
	add(lock);

	return {award: award, bg: bg, icon: icon, name: name, desc: desc, lock: lock, baseY: y};
}

function update(elapsed:Float) {
	if (controls.BACK || FlxG.keys.justPressed.ESCAPE || FlxG.mouse.justPressedRight)
		FlxG.switchState(new ModState("VoiidMainMenuState"));

	scroll = FlxMath.bound(scroll - FlxG.mouse.wheel * 70 + ((controls.DOWN ? 1 : 0) - (controls.UP ? 1 : 0)) * 700 * elapsed, 0, maxScroll);

	for (card in cards) {
		var y = card.baseY - scroll;
		card.bg.y = y;
		card.icon.y = y + 9;
		card.name.y = y + 10;
		card.desc.y = y + 55;
		card.lock.y = y + 38;

		var unlocked = isUnlocked(card.award.save);
		card.icon.alpha = unlocked ? 1 : 0.25;
		card.name.alpha = unlocked ? 1 : 0.45;
		card.desc.alpha = unlocked ? 0.78 : 0.35;
		card.lock.visible = !unlocked;

		var hovered = FlxG.mouse.overlaps(card.bg);
		card.bg.color = hovered ? 0xFF6E27CA : 0xFFFFFFFF;
		card.bg.alpha = hovered ? 0.88 : 0.72;
	}
}

function updatePercent() {
	var unlocked = 0;
	for (award in awards)
		if (isUnlocked(award.save))
			unlocked++;
	var percent = awards.length <= 0 ? 0 : Math.round((unlocked / awards.length) * 10000) / 100;
	percentText.text = percent + "% (" + unlocked + "/" + awards.length + ")";
}
