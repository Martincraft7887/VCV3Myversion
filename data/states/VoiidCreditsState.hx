import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxTextBorderStyle;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import funkin.backend.FunkinText;
import funkin.backend.scripting.ModState;
import haxe.Json;
import lime.utils.Assets;

using StringTools;

var creditsData:Dynamic;
var sectionIndex:Int = 0;
var creditIndex:Int = 0;
var sectionSprite:FlxSprite;
var icon:FlxSprite;
var selector:FlxSprite;
var descText:FunkinText;
var creditTexts:Array<FunkinText> = [];
var iconBump:Float = 1;

function create() {
	CoolUtil.playMenuSong();
	FlxG.mouse.visible = true;

	add(fullImage("credits/Credits-BG", 1));

	var side = new FlxSprite().loadGraphic(Paths.image("credits/rectangle"));
	side.x = FlxG.width - side.width;
	side.screenCenter(FlxAxes.Y);
	side.antialiasing = Options.antialiasing;
	add(side);

	creditsData = Json.parse(Assets.getText(Paths.json("credits")));

	selector = new FlxSprite().loadGraphic(Paths.image("credits/arrow"));
	selector.setGraphicSize(42, 42);
	selector.updateHitbox();
	selector.antialiasing = Options.antialiasing;
	add(selector);

	descText = new FunkinText(35, FlxG.height - 165, 470, "", 30, true);
	descText.font = Paths.font("Contb___.ttf");
	descText.borderStyle = FlxTextBorderStyle.OUTLINE;
	descText.borderColor = FlxColor.BLACK;
	add(descText);

	updateSection();
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

function update(elapsed:Float) {
	if (FlxG.keys.justPressed.LEFT || controls.LEFT_P) changeSection(-1);
	if (FlxG.keys.justPressed.RIGHT || controls.RIGHT_P) changeSection(1);
	if (FlxG.keys.justPressed.UP || controls.UP_P || FlxG.mouse.wheel > 0) changeCredit(-1);
	if (FlxG.keys.justPressed.DOWN || controls.DOWN_P || FlxG.mouse.wheel < 0) changeCredit(1);
	if (controls.BACK || FlxG.keys.justPressed.ESCAPE || FlxG.mouse.justPressedRight) FlxG.switchState(new ModState("VoiidMainMenuState"));
	if ((controls.ACCEPT || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE) && currentCredit().link != null && Std.string(currentCredit().link).trim() != "")
		CoolUtil.openURL(Std.string(currentCredit().link));

	for (i in 0...creditTexts.length) {
		var t = creditTexts[i];
		var offset = i - creditIndex;
		t.y = FlxMath.lerp(t.y, 170 + offset * 66, elapsed * 12);
		t.x = FlxMath.lerp(t.x, FlxG.width * 0.73 + (i == creditIndex ? -18 : 0), elapsed * 10);
		t.alpha = Math.abs(offset) > 5 ? 0 : (i == creditIndex ? 1 : 0.55);
		t.scale.set(i == creditIndex ? 1.08 : 1, i == creditIndex ? 1.08 : 1);

		if (FlxG.mouse.overlaps(t)) {
			creditIndex = i;
			updateCredit();
			if (FlxG.mouse.justPressed && currentCredit().link != null && Std.string(currentCredit().link).trim() != "")
				CoolUtil.openURL(Std.string(currentCredit().link));
		}
	}

	var target = creditTexts[creditIndex];
	if (target != null) {
		selector.x = FlxMath.lerp(selector.x, target.x - 50, elapsed * 15);
		selector.y = FlxMath.lerp(selector.y, target.y + target.height * 0.5 - selector.height * 0.5, elapsed * 15);
	}

	if (icon != null) {
		iconBump = FlxMath.lerp(iconBump, 1, elapsed * 6);
		scaleIcon();
	}
}

function beatHit(curBeat:Int) {
	iconBump = 1.15;
}

function currentSection():Dynamic {
	return creditsData.sections[sectionIndex];
}

function currentCredit():Dynamic {
	return currentSection().people[creditIndex];
}

function changeSection(change:Int) {
	sectionIndex = FlxMath.wrap(sectionIndex + change, 0, creditsData.sections.length - 1);
	creditIndex = 0;
	CoolUtil.playMenuSFX(0, 0.7);
	updateSection();
}

function changeCredit(change:Int) {
	creditIndex = FlxMath.wrap(creditIndex + change, 0, currentSection().people.length - 1);
	CoolUtil.playMenuSFX(0, 0.7);
	updateCredit();
}

function updateSection() {
	for (t in creditTexts) {
		remove(t);
		t.destroy();
	}
	creditTexts = [];

	if (sectionSprite != null) {
		remove(sectionSprite);
		sectionSprite.destroy();
	}

	sectionSprite = new FlxSprite().loadGraphic(Paths.image("credits/" + currentSection().imageName));
	sectionSprite.antialiasing = Options.antialiasing;
	sectionSprite.x = FlxG.width * 0.83 - sectionSprite.width * 0.5;
	sectionSprite.y = 72;
	add(sectionSprite);

	for (i in 0...currentSection().people.length) {
		var person = currentSection().people[i];
		var size = Std.int(Math.max(30, Math.min(58, 700 / Math.max(12, Std.string(person.name).length))));
		var text = new FunkinText(FlxG.width * 0.73, 170 + i * 66, 350, Std.string(person.name), size, true);
		text.font = Paths.font("Contb___.ttf");
		text.borderStyle = FlxTextBorderStyle.OUTLINE;
		text.borderColor = FlxColor.BLACK;
		text.alignment = "center";
		add(text);
		creditTexts.push(text);
	}

	updateCredit();
}

function updateCredit() {
	var c = currentCredit();
	descText.text = Std.string(c.desc);

	if (icon != null) {
		remove(icon);
		icon.destroy();
	}

	var iconPath = "credits/icons/" + Std.string(c.icon);
	if (!Assets.exists(Paths.image(iconPath))) iconPath = "credits/icons/none";

	icon = new FlxSprite().loadGraphic(Paths.image(iconPath));
	icon.antialiasing = Options.antialiasing;
	add(icon);
	scaleIcon();
}

function scaleIcon() {
	var scale = currentCredit().iconScale == null ? 0.7 : currentCredit().iconScale;
	icon.scale.set(scale * iconBump, scale * iconBump);
	icon.updateHitbox();
	icon.x = FlxG.width * 0.33 - icon.width * 0.5;
	icon.y = 250 - icon.height * 0.5;
}
