import flixel.FlxSprite;
import flixel.util.FlxColor;

var particleSpawnTime:Float = 0.01;
var particleTime:Float = 0;
var particleCount:Int = 0;

var velocityAngle:Float = 140;
var velocitySpeed:Float = 8000;

var spawnX:Float = 0;
var spawnWidth:Float = 6000;
var spawnY:Float = 300;

var poolLimit:Int = 200;
var rainParticles:Array<FlxSprite> = [];

var piss:Bool = false;
var pis:Int = 0;
var rainShader:CustomShader = null;
var rainShaderTime:Float = 0;
var shaderRainSongs:Array<String> = [
	"veteran",
	"venom",
	"edgy vip",
	"veteran vip"
];

function shouldUseShaderRain():Bool {
	return SONG != null && SONG.meta != null && shaderRainSongs.contains(SONG.meta.name.toLowerCase());
}

function postCreate() {
	if (SONG.meta.name.toLowerCase() == "banger") {
		particleSpawnTime = 0.006;
	} else if (SONG.meta.name.toLowerCase() == "edgy") {
		particleSpawnTime = 0.003;
	}

	if (shouldUseShaderRain()) {
		rainShader = new CustomShader("rain");
		camGame.addShader(rainShader);
		rainShader.iIntensity = 0.05;
		rainShader.iTimescale = 0.7;
	}

	initPool();
}

function update(elapsed:Float) {
	if (rainShader != null) {
		rainShaderTime += elapsed;
		rainShader.iTime = rainShaderTime;
	}

	particleTime += elapsed;

	while (particleTime >= particleSpawnTime) {
		particleTime -= particleSpawnTime;
		makeParticle();
	}

	if ((pis == 0 && FlxG.keys.justPressed.P) ||
		(pis == 1 && FlxG.keys.justPressed.I) ||
		(pis > 1 && FlxG.keys.justPressed.S)) {
		pis++;

		if (pis >= 4) {
			piss = true;
		}
	}
}

function lerp(a:Float, b:Float, ratio:Float):Float {
	return a + ratio * (b - a);
}

function initPool() {
	for (i in 0...poolLimit + 1) {
		var spr = new FlxSprite(-10000, 0);
		spr.makeGraphic(100, 5, FlxColor.WHITE);
		spr.alpha = 0;
		spr.cameras = [camGame];

		insert(members.indexOf(dad) + 2, spr);

		rainParticles.push(spr);
	}
}

function makeParticle() {
	var spr = rainParticles[particleCount];

	var pos = lerp(spawnX, spawnX + spawnWidth, FlxG.random.float());

	spr.x = pos;
	spr.y = spawnY;

	spr.color = piss ? FlxColor.YELLOW : FlxColor.WHITE;
	spr.angle = velocityAngle;
	spr.alpha = lerp(0.25, 0.7, FlxG.random.float());

	var radians = velocityAngle * Math.PI / 180;

	spr.velocity.x = Math.cos(radians) * velocitySpeed;
	spr.velocity.y = Math.sin(radians) * velocitySpeed;

	var scroll = lerp(0.8, 1.3, FlxG.random.float());
	spr.scrollFactor.set(scroll, scroll);

	particleCount++;

	if (particleCount > poolLimit) {
		particleCount = 0;
	}
}
