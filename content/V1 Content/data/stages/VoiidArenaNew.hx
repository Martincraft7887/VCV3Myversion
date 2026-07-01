import funkin.backend.shaders.CustomShader;
public var camScreen:FlxCamera;
function postCreate() {

	FlxG.cameras.remove(camHUD, false);

	FlxG.cameras.add(camScreen = new FlxCamera(), false);
	camScreen.bgColor = 0;
	FlxG.cameras.add(camHUD, false);

	for (s in strumLines) {
		for (char in s.characters) {
			char.forceIsOnScreen = true;
		}
	}

	
	
}

var loaded = false;
function postUpdate(elapsed) {
	if (!loaded) { 

		
		stage.stageSprites["screen"].cameras = [camScreen];
		stage.stageSprites["grain"].cameras = [camScreen];
		stage.stageSprites["screen"].shader = new CustomShader("screenShader");
		loaded = true;
	}
	FlxG.camera.canvas.__cacheAsBitmap = true; 
	if (FlxG.camera.canvas.__cacheBitmapRenderer != null) {
		
		stage.stageSprites["screen"].shader.screenBitmap = FlxG.camera.canvas.__cacheBitmap.bitmapData;
		stage.stageSprites["screen"].shader.zoom = FlxG.camera.zoom;
		stage.stageSprites["screen"].shader.width = FlxG.camera.canvas.__cacheBitmap.bitmapData.width; 
		stage.stageSprites["screen"].shader.height = FlxG.camera.canvas.__cacheBitmap.bitmapData.height;

		stage.stageSprites["screen"].shader.scale = FlxG.scaleMode.scale.x > FlxG.scaleMode.scale.y ? FlxG.scaleMode.scale.x : FlxG.scaleMode.scale.y;
	}

	camScreen.scroll = camGame.scroll;
	camScreen.zoom = camGame.zoom;
	camScreen.angle = camGame.zoom;
	camScreen._filters = camGame._filters;


	for (s in strumLines) {
		for (char in s.characters) {
			char.cameraOffset.y = -980 / (camGame.zoom*10);
		}
	}

	
}