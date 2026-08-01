var PUNCH_TIME = 333;
var echosData = [];
var activeEchos = [];
var nextEchoIndex:Int = 0;
public var colorswapShader:CustomShader;
var rejectedEchoShader:CustomShader = null;
var lastTime = -5000;
var lastCount = 0;

var attackSpriteSheets = [
	"Wiik3Purple" => "characters/MattStand_Attack",
	"Wiik3White" => "characters/WhiteMattStand_Attack",
	"Wiik4Purple" => "characters/MattSlash",
	"Wiik4White" => "characters/WhiteMattSlash",
	"GreedBlast" => "characters/GreedBlast"
];

function isRejectedVIP():Bool {
	return curSong != null && curSong.toLowerCase() == "rejected vip";
}

function getEchoShader():Dynamic {
	if (!isRejectedVIP())
		return colorswapShader;

	if (rejectedEchoShader == null) {
		rejectedEchoShader = new CustomShader("colorswap");
		rejectedEchoShader.hue = -0.66;
	}

	return rejectedEchoShader;
}

function onEchoCreate(time, name) {
	
	switch(name) {
		case "Wiik3Purple" | "Wiik3White":
			var data = {
				time: time - PUNCH_TIME,
				type: "attack",
				name: name,
				sprite: new FunkinSprite(),
				started: false,
				finished: false,
				offsetX: 0,
				offsetY: 0
			};
			data.sprite.frames = Paths.getSparrowAtlas(attackSpriteSheets.get(name));
			data.sprite.animation.addByPrefix("attack", "attack", 24, false);
			var echoScale = getEchoScale(1.5);
			data.sprite.scale.set(echoScale, echoScale);
			data.sprite.updateHitbox();

			if (time-lastTime < 1000) {
				lastCount++;

				if (lastCount == 1) data.sprite.flipX = true;

				if (lastCount == 2) {
					data.sprite.flipX = false;


					data.sprite.skew.y = 10;
					data.sprite.skew.x = 0;
					data.offsetX += 150;
				}
				
				if (lastCount == 3) {
					data.sprite.flipX = true;


					data.sprite.skew.y = -10;
					data.sprite.skew.x = 0;
					data.offsetX -= 300;
				}
				if (lastCount == 4) lastCount = 0;

				
				
			} else {
				lastCount = 0;
			}
			echosData.push(data);
		case "Wiik4Purple" | "Wiik4White":
			var data = {
				time: time - PUNCH_TIME,
				type: "attack",
				name: name,
				sprite: new FunkinSprite(),
				started: false,
				finished: false,
				offsetX: 0,
				offsetY: 0
			};
			data.sprite.frames = Paths.getSparrowAtlas(attackSpriteSheets.get(name));
			data.sprite.animation.addByPrefix("attack", "mattslash", 24, false);
			var echoScale = getEchoScale(1.5);
			data.sprite.scale.set(echoScale, echoScale);
			data.sprite.updateHitbox();

			if (time-lastTime < 1000) {
				lastCount++;

				if (lastCount == 1) data.sprite.flipX = true;

				if (lastCount == 2) {
					data.sprite.flipX = false;


					data.sprite.skew.y = 10;
					data.sprite.skew.x = 0;
					data.offsetX += 150;
				}
				
				if (lastCount == 3) {
					data.sprite.flipX = true;


					data.sprite.skew.y = -10;
					data.sprite.skew.x = 0;
					data.offsetX -= 300;
				}
				if (lastCount == 4) lastCount = 0;
				
			} else {
				lastCount = 0;
			}
			echosData.push(data);
		case "Wiik2":
			var data = {
				time: time - 725,
				type: "Wiik2",
				name: name,
				sprite: new FunkinSprite(),
				glove: new FlxSprite(),
				splash: new FlxSprite(),
				started: false,
				finished: false,
				offsetX: 0,
				offsetY: 0
			};
			data.sprite.frames = Paths.getSparrowAtlas("characters/Wiik_2_Echo");
			data.sprite.animation.addByPrefix("attack", "attack", 24, false);
			var echoScale = getEchoScale(1.5);
			data.sprite.scale.set(echoScale, echoScale);
			data.sprite.updateHitbox();

			data.glove.frames = Paths.getSparrowAtlas("characters/EchoGlove");
			data.glove.animation.addByPrefix("echoglove", "echoglove", 24, true); 
			data.glove.animation.play("echoglove");
			data.glove.angle = 45;

			data.splash.frames = Paths.getSparrowAtlas("characters/Splash");
			data.splash.animation.addByPrefix("splash", "splash", 24, false);
			data.splash.visible = false;

			if (time-lastTime < 1000) {
				lastCount++;

				if (lastCount == 1) data.sprite.flipX = true;

				if (lastCount == 2) {
					data.sprite.flipX = false;

					data.offsetX += 200;
					data.offsetY -= 200;
				}
				
				if (lastCount == 3) {
					data.sprite.flipX = true;

					data.offsetX -= 200;
					data.offsetY -= 200;
				}
				if (lastCount == 4) lastCount = 0;

			} else {
				lastCount = 0;
			}
			echosData.push(data);
		case "GreedBlast":
			var data = {
				time: time - 220,
				type: "greedBlast",
				name: name,
				sprite: new FunkinSprite(),
				started: false,
				finished: false,
				offsetX: 0,
				offsetY: 0
			};
			data.sprite.frames = Paths.getSparrowAtlas(attackSpriteSheets.get(name));
			data.sprite.animation.addByPrefix("blast", "GREEDBLAST", 36, false);
			var echoScale = 1.45;
			data.sprite.scale.set(echoScale, echoScale);
			data.sprite.updateHitbox();

			if (time-lastTime < 1000) {
				lastCount++;

				if (lastCount == 1) {
					data.offsetX += 120;
					data.offsetY -= 35;
				}

				if (lastCount == 2) {
					data.offsetX -= 130;
					data.offsetY += 25;
				}

				if (lastCount == 3) {
					data.offsetX += 230;
					data.offsetY -= 85;
				}
				if (lastCount == 4) lastCount = 0;
			} else {
				lastCount = 0;
			}
			echosData.push(data);
	}
	lastTime = time;
}
var firstFrame = true;
function postUpdate(elapsed) {
	if (echosData.length <= 0)
		return;

	if (firstFrame) {
		firstFrame = false;
		echosData.sort(function(a, b) {
			if(a.time < b.time) return -1;
			else if(a.time > b.time) return 1;
			else return 0;
		 });
	}

	// Advance through the immutable, sorted timeline. Removing the first item
	// from the full future array for every completed echo repeatedly shifted
	// hundreds of entries during dense punch sections.
	while (nextEchoIndex < echosData.length) {
		var nextEcho = echosData[nextEchoIndex];
		if (Conductor.songPosition < nextEcho.time)
			break;

		nextEcho.started = true;
		onEchoStart(nextEcho);
		activeEchos.push(nextEcho);
		nextEchoIndex++;
	}

	var echoIndex = 0;
	while (echoIndex < activeEchos.length) {
		var echo = activeEchos[echoIndex];
		onEchoUpdate(echo);

		if (echo.finished) {
			onEchoFinish(echo);
			activeEchos.splice(echoIndex, 1);
			continue;
		}

		echoIndex++;
	}
}

function onEchoStart(echo) {
	switch(echo.type) {
		case "attack":
			insert(members.indexOf(boyfriend)+1, echo.sprite);
			echo.sprite.animation.play("attack");
			echo.sprite.shader = getEchoShader();

			switch(echo.name) {
				case "Wiik3Purple" | "Wiik3White":
					if (echo.sprite.flipX) {
						echo.sprite.x = echo.offsetX + boyfriend.x+(760+FlxG.random.float(-20,20))-(echo.sprite.width-300);
					} else {
						echo.sprite.x = echo.offsetX + boyfriend.x-(950+FlxG.random.float(-20,20));
					}
					echo.sprite.y = echo.offsetY + boyfriend.y-(80+410+FlxG.random.float(-5,5));

					echo.sprite.scale.x*1.5;
					echo.sprite.scale.y*1.5;
				case "Wiik4Purple" | "Wiik4White":
					if (echo.sprite.flipX) {
						echo.sprite.x = echo.offsetX + boyfriend.x+(1200+FlxG.random.float(-20,20))-(echo.sprite.width-300);
					} else {
						echo.sprite.x = echo.offsetX + boyfriend.x-(1400+FlxG.random.float(-20,20));
					}
					echo.sprite.y = echo.offsetY + boyfriend.y-(870+FlxG.random.float(-5,5));

					echo.sprite.scale.x*1.5;
					echo.sprite.scale.y*1.5;
			}
		case "Wiik2":
			insert(members.indexOf(boyfriend)+1, echo.sprite);
			echo.sprite.animation.play("attack");
			echo.sprite.shader = getEchoShader();
			echo.glove.shader = getEchoShader();

			if (echo.sprite.flipX) {
				echo.sprite.x = echo.offsetX + boyfriend.x+(700+FlxG.random.float(-100,100))-(echo.sprite.width-boyfriend.width);
				echo.glove.x = echo.sprite.x;
			} else {
				echo.sprite.x = echo.offsetX + boyfriend.x-(950+FlxG.random.float(-100,100));
				echo.glove.x = (echo.sprite.x + echo.sprite.width)-250;
			}

			echo.sprite.y = echo.offsetY + boyfriend.y-(750+FlxG.random.float(-100,100));
			echo.glove.y = echo.sprite.y + 100;

			echo.splash.x = boyfriend.x - 270;
			echo.splash.y = boyfriend.y - 150;

			if (echo.sprite.flipX) {
				echo.glove.angle += 90;
			}

			var targetX = boyfriend.x - 270;
			var targetY = boyfriend.y - 50;

			new FlxTimer().start((1/24)*15, function(tmr) {
				insert(members.indexOf(boyfriend)+1, echo.glove);
				FlxTween.tween(echo.glove, {x: targetX, y: targetY}, 0.1, {onComplete:function(twn) {
					echo.glove.visible = false;

					insert(members.indexOf(boyfriend)-1, echo.splash);
					echo.splash.visible = true;
					echo.splash.animation.play("splash");
				}});
			});



		case "greedBlast":
			insert(members.indexOf(boyfriend)+1, echo.sprite);
			echo.sprite.animation.play("blast");
			echo.sprite.x = echo.offsetX + boyfriend.x - (echo.sprite.width * 0.68);
			echo.sprite.y = echo.offsetY + boyfriend.y - (echo.sprite.height * 0.98);
			
	}
}
function onEchoUpdate(echo) {
	switch(echo.type) {
		case "attack":
			if (echo.sprite.animation.curAnim.finished) {
				echo.finished = true;
			}
		case "greedBlast":
			if (echo.sprite.animation.curAnim.finished) {
				echo.finished = true;
			}
		case "Wiik2":
			if (echo.splash.visible && echo.splash.animation.curAnim.finished && echo.sprite.animation.curAnim.finished) {
				echo.finished = true;
			}
	}
}
function onEchoFinish(echo) {
	switch(echo.type) {
		case "attack" | "greedBlast":
			if (members.indexOf(echo.sprite) >= 0)
				remove(echo.sprite, true);
		case "Wiik2":
			if (members.indexOf(echo.sprite) >= 0)
				remove(echo.sprite, true);
			if (members.indexOf(echo.glove) >= 0)
				remove(echo.glove, true);
			if (members.indexOf(echo.splash) >= 0)
				remove(echo.splash, true);
	}

	// Echoes are one-shot. Retaining all completed objects until song end and
	// removing them without splicing left permanent holes in PlayState.members.
	destroyEcho(echo);
}

function destroyEcho(echo) {
	switch(echo.type) {
		case "attack" | "greedBlast":
			if (echo.sprite != null) {
				FlxTween.cancelTweensOf(echo.sprite);
				echo.sprite.destroy();
				echo.sprite = null;
			}
		case "Wiik2":
			if (echo.sprite != null) {
				FlxTween.cancelTweensOf(echo.sprite);
				echo.sprite.destroy();
				echo.sprite = null;
			}
			if (echo.glove != null) {
				FlxTween.cancelTweensOf(echo.glove);
				echo.glove.destroy();
				echo.glove = null;
			}
			if (echo.splash != null) {
				FlxTween.cancelTweensOf(echo.splash);
				echo.splash.destroy();
				echo.splash = null;
			}
	}
}

function destroy() {
	for (echo in echosData) {
		destroyEcho(echo);
		echo = null;
	}
	echosData.splice(0, echosData.length);
	activeEchos.splice(0, activeEchos.length);
	nextEchoIndex = 0;
}

function getEchoScale(defaultScale:Float):Float {
	var bfScale = getBoyfriendScale();
	return defaultScale * Math.max(0.55, Math.min(1.15, bfScale));
}

function getBoyfriendScale():Float {
	if (boyfriend == null)
		return 1;
	try {
		if (boyfriend.scale != null && boyfriend.scale.y > 0)
			return boyfriend.scale.y;
	} catch(e:Dynamic) {}
	return 1;
}
