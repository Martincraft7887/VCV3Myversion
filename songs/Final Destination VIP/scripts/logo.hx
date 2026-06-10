import VCSongText;
import flixel.util.FlxTimer;

// ==========================
// CONFIG HARD CODE
// ==========================
var hardcodedData = '
{
	"composer": "TheOnlyVolume,Wolfinu,ImSilv4,Aron_Aurora",
	"charter": "Sharik,Sanek,Parko",
	"originalComposer": "Srperez",

	"startTime": 156800,

	"songFont": "dumbnerd.ttf",
	"songFontSize": 64,
	"infoFontSize": 12,

	"diagonalSplit": true,
	"splitAngle": 45,
	"splitSoftness": 0.25,
	"splitOffset": 0.15,

	"outerBorderTop": "#000000",
	"outerBorderBot": "#000000",

	"midBorderTop": "#1ffbfe",
	"midBorderBot": "#ffa8f2",

	"innerBorderTop": "#1595f1",
	"innerBorderBot": "#5a3cb1",

	"leftOuterBorderTop": "#000000",
	"leftOuterBorderBot": "#000000",
	"leftMidBorderTop": "#1ffbfe",
	"leftMidBorderBot": "#1595f1",
	"leftInnerBorderTop": "#2a8cb5",
	"leftInnerBorderBot": "#0d3f88",

	"rightOuterBorderTop": "#000000",
	"rightOuterBorderBot": "#000000",
	"rightMidBorderTop": "#ff4bd8",
	"rightMidBorderBot": "#ff7a1f",
	"rightInnerBorderTop": "#b64f9f",
	"rightInnerBorderBot": "#8f1f00",

	"textOffsetY": 120,

	"logo": "FDVIP",
	"logoOffsetY": 0,
	"logoScale": 1,

	"sobelStrength": 0.6,
	"sobelIntensity": 1.0,

	"vipFont": "Onslaughter.otf",

	"outerBorderTopVIP": "#000000",
	"outerBorderBotVIP": "#000000",
	"midBorderTopVIP": "#474747",
	"midBorderBotVIP": "#474747",
	"innerBorderTopVIP": "#FFFFFF",
	"innerBorderBotVIP": "#FFFFFF",

	"outerBorderSize": 5,
	"midBorderSize": 2,
	"innerBorderSize": 2
}';

// ==========================
// VARIABLES
// ==========================
var Textiyo;
var logo;
var showedPopup:Bool = false;

var songData = null;

var centerFollowers:Array<Dynamic> = [];
var centerFollowLerp:Float = 0.12;

var logoHasIdleAnim:Bool = false;
var logoBaseScaleX:Float = 1;
var logoBaseScaleY:Float = 1;
var logoBumpTween:FlxTween = null;

// ==========================
// HELPERS
// ==========================
function getJsonFloat(field:String, fallback:Float):Float
{
	if (songData == null || Reflect.field(songData, field) == null)
		return fallback;

	var value = Std.parseFloat(Std.string(Reflect.field(songData, field)));
	return Math.isNaN(value) ? fallback : value;
}

function logoExists(logoName:String):Bool
{
	return Assets.exists(Paths.image("logos/" + logoName));
}

function getLogoName():String
{
	if (songData != null && songData.logo != null && Std.string(songData.logo) != "")
	{
		var jsonLogo = Std.string(songData.logo);
		if (logoExists(jsonLogo))
			return jsonLogo;
	}

	return "Logo";
}

// ==========================
// INIT
// ==========================
function postCreate()
{
	songData = Json.parse(hardcodedData);

	Textiyo = makeCoolText(
		PlayState.SONG.meta.displayName,
		songData.songFontSize,
		12,
		Json.stringify(songData)
	);

	var logoName = getLogoName();

	logo = new FlxSprite();
	logo.frames = Paths.getFrames("logos/" + logoName);

	logo.animation.addByPrefix("idle", "idle", 24, false);

	logoHasIdleAnim = logo.animation.exists("idle");
	if (logoHasIdleAnim)
		logo.animation.play("idle");

	var logoScale:Float = getJsonFloat("logoScale", 0.8);

	logo.setGraphicSize(Std.int(logo.width * logoScale));
	logo.updateHitbox();

	logoBaseScaleX = logo.scale.x;
	logoBaseScaleY = logo.scale.y;

	logo.cameras = [camHUD];
	logo.scrollFactor.set(1, 1);
	logo.visible = false;

	add(logo);

    var strumIndex = members.indexOf(strumLines);

if (strumIndex != -1)
{
    remove(Textiyo);
    insert(strumIndex, Textiyo);

    remove(logo);
    insert(strumIndex, logo);
}
}

// ==========================
// CREAR TEXTO
// ==========================
function makeCoolText(text:String, size:Float, spacing:Float, dataString:String)
{
	var data = Json.parse(dataString);

	var t = createSongText(text, size, spacing, data);

	t.cameras = [camHUD];
	t.scrollFactor.set(1, 1);
	t.visible = false;

	add(t);

	return t;
}

// ==========================
// POSICIONES
// ==========================
function setupEnter(obj:FlxSprite, enterDir:String, targetX:Float, targetY:Float)
{
	switch(enterDir)
	{
		case "down":
			obj.x = targetX;
			obj.y = FlxG.height + 200;

		case "up":
			obj.x = targetX;
			obj.y = -obj.height - 200;

		case "left":
			obj.x = -obj.width - 200;
			obj.y = targetY;

		case "right":
			obj.x = FlxG.width + obj.width + 200;
			obj.y = targetY;
	}
}

function getExitPos(obj:FlxSprite, exitDir:String, targetX:Float, targetY:Float)
{
	var pos = {
		x: targetX,
		y: targetY
	};

	switch(exitDir)
	{
		case "down":
			pos.y = FlxG.height + 200;

		case "up":
			pos.y = -obj.height - 200;

		case "left":
			pos.x = -obj.width - 200;

		case "right":
			pos.x = FlxG.width + obj.width + 200;
	}

	return pos;
}

function getCenteredPos(obj:FlxSprite, xOffset:Float, yOffset:Float)
{
	return {
		x: (FlxG.width - obj.width) / 2 + xOffset,
		y: (FlxG.height - obj.height) / 2 + yOffset
	};
}

function followCenter(obj:FlxSprite, xOffset:Float, yOffset:Float)
{
	for (data in centerFollowers)
	{
		if (data.obj == obj)
		{
			data.xOffset = xOffset;
			data.yOffset = yOffset;
			data.active = true;
			return data;
		}
	}

	var data = {
		obj: obj,
		xOffset: xOffset,
		yOffset: yOffset,
		active: true
	};

	centerFollowers.push(data);
	return data;
}

function stopFollowingCenter(obj:FlxSprite)
{
	for (data in centerFollowers)
	{
		if (data.obj == obj)
			data.active = false;
	}
}

function updateCenterFollowers(elapsed:Float)
{
	var ratio = 1 - Math.pow(1 - centerFollowLerp, elapsed * 60);

	for (data in centerFollowers)
	{
		if (data.active && data.obj != null && data.obj.visible)
		{
			var pos = getCenteredPos(data.obj, data.xOffset, data.yOffset);
			data.obj.x += (pos.x - data.obj.x) * ratio;
			data.obj.y += (pos.y - data.obj.y) * ratio;
		}
	}
}

// ==========================
// MOSTRAR OBJETO
// ==========================
function showObject(
	obj:FlxSprite,
	enterDir:String,
	exitDir:String,
	durationMS:Int,
	xOffset:Float,
	yOffset:Float
)
{
	obj.visible = true;

	stopFollowingCenter(obj);

	var targetPos = getCenteredPos(obj, xOffset, yOffset);
	var targetX = targetPos.x;
	var targetY = targetPos.y;

	setupEnter(obj, enterDir, targetX, targetY);

	FlxTween.tween(obj,
	{
		x: targetX,
		y: targetY
	},
	0.8,
	{
		ease: FlxEase.expoOut,

		onComplete: function(_)
		{
			followCenter(obj, xOffset, yOffset);

			new FlxTimer().start(durationMS / 1000, function(_)
			{
				stopFollowingCenter(obj);

				var centeredPos = getCenteredPos(obj, xOffset, yOffset);
				obj.x = centeredPos.x;
				obj.y = centeredPos.y;

				var exitPos = getExitPos(
					obj,
					exitDir,
					centeredPos.x,
					centeredPos.y
				);

				FlxTween.tween(obj,
				{
					x: exitPos.x,
					y: exitPos.y
				},
				0.4,
				{
					ease: FlxEase.expoIn,

					onComplete: function(_)
					{
						obj.visible = false;
					}
				});
			});
		}
	});
}

// ==========================
// UPDATE
// ==========================
function update(elapsed)
{
	updateCenterFollowers(elapsed);

	if (!showedPopup)
	{
		var popupTime:Float = getJsonFloat("startTime", 0);

		if (popupTime == -1)
		{
			showedPopup = true;
			return;
		}

		if (Conductor.songPosition >= popupTime)
		{
			showedPopup = true;

			showObject(
				Textiyo,
				"down",
				"right",
				2500,
				0,
				getJsonFloat("textOffsetY", 200)
			);

			showObject(
				logo,
				"left",
				"up",
				2500,
				0,
				-100 + getJsonFloat("logoOffsetY", 0)
			);
		}
	}
}

// ==========================
// BEAT LOGO
// ==========================
function beatHit(curBeat:Int)
{
	if (logo != null && logo.visible)
	{
		if (logoHasIdleAnim)
		{
			logo.animation.play("idle", true);
		}
		else
		{
			if (logoBumpTween != null)
				logoBumpTween.cancel();

			var cx = logo.x + logo.width / 2;
			var cy = logo.y + logo.height / 2;

			logo.scale.set(logoBaseScaleX * 1.08, logoBaseScaleY * 1.08);
			logo.updateHitbox();

			logo.x = cx - logo.width / 2;
			logo.y = cy - logo.height / 2;

			logoBumpTween = FlxTween.tween(
				logo.scale,
				{x: logoBaseScaleX, y: logoBaseScaleY},
				0.18,
				{
					ease: FlxEase.quadOut,
					onUpdate: function(_)
					{
						logo.updateHitbox();
						logo.x = cx - logo.width / 2;
						logo.y = cy - logo.height / 2;
					}
				}
			);
		}
	}
}