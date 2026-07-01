var shaderEaseList = [
	"linear",

	"quadIn",
	"quadOut",
	"quadInOut",

	"cubeIn",
	"cubeOut",
	"cubeInOut",

	"quartIn",
	"quartOut",
	"quartInOut",

	"quintIn",
	"quintOut",
	"quintInOut",

	"smoothStepIn",
	"smoothStepOut",
	"smoothStepInOut",

	"smootherStepIn",
	"smootherStepOut",
	"smootherStepInOut",

	"sineIn",
	"sineOut",
	"sineInOut",

	"bounceIn",
	"bounceOut",
	"bounceInOut",

	"circIn",
	"circOut",
	"circInOut",

	"expoIn",
	"expoOut",
	"expoInOut",

	"backIn",
	"backOut",
	"backInOut",

	"elasticIn",
	"elasticOut",
	"elasticInOut",
];

class EventRenderer extends funkin.editors.ui.UISprite {
	public var conductorPos:Float = 0;
	public var sizeX:Float = 20;
	public var sizeY:Float = 20;
	public var _timelineScrollY:Float = 0;

	public var events = [];

	public function getVarForEachAdd(e:Dynamic) {
		return e.step + (e.time != null ? e.time : 0);
	}
		
	public function getVarForEachRemove(e:Dynamic) {
		return e.step - (e.time != null ? e.time : 0);
	}

	public function getVar(n:Dynamic)
		return e.step;

	public function getVisibleStartIndex() {
		return SortedArrayUtil.binarySearch(events, conductorPos-1, getVarForEachAdd);
	}
	public function getVisibleEndIndex() {
		return SortedArrayUtil.binarySearch(events, conductorPos+((1280-250)/sizeX), getVarForEachRemove);
	}

	public var easeSpritesUp = [];
	public var easeSpritesDown = [];

	public var arrows = [];
	public var arrowsSelected = [];

	public function new() {
		super();

		for (a in 0...4) {
			var arr = new UISprite(0, 0);
			arr.loadGraphic(Paths.image('editors/charter/note'), true, 157, 154);
			arr.animation.add("note", [for(i in 0...arr.frames.frames.length) i], 0, true);
			arr.animation.play("note");
			arr.setGraphicSize(20,20);
			arr.updateHitbox();
			arr.animation.curAnim.curFrame = a;
			arrows.push(arr);

			var arrS = new UISprite(0, 0);
			arrS.loadGraphic(Paths.image('editors/charter/note'), true, 157, 154);
			arrS.animation.add("note", [for(i in 0...arrS.frames.frames.length) i], 0, true);
			arrS.animation.play("note");
			arrS.setGraphicSize(20,20);
			arrS.updateHitbox();
			arrS.animation.curAnim.curFrame = a;
			arrowsSelected.push(arrS);

			if (a == 1) {
				arr.flipY = true;
				arrS.flipY = true;
			}

			arrS.colorTransform.redMultiplier = arrS.colorTransform.greenMultiplier = arrS.colorTransform.blueMultiplier = 0.75;
			arrS.colorTransform.redOffset = arrS.colorTransform.greenOffset = 96;
			arrS.colorTransform.blueOffset = 168;
		}

		for (i => ease in shaderEaseList) {
			var up = new UISprite(0, 0);
			up.makeSolid(1, 1, -1);
			up.shader = new CustomShader("ease");
			up.shader.easeType = i;
			up.shader.flip = 1;
			easeSpritesUp.push(up);

			var down = new UISprite(20, 10);
			down.makeSolid(1, 1, -1);
			down.shader = new CustomShader("ease");
			down.shader.easeType = i;
			down.shader.flip = 0;
			easeSpritesDown.push(down);
		}
	}

	override public function draw() {

		var begin = getVisibleStartIndex();
		var end = getVisibleEndIndex();

		var minTimelineIndex = Math.floor(_timelineScrollY / sizeY) - 1;
		var maxTimelineIndex = minTimelineIndex + Math.ceil(320 / sizeY) + 1;

		for(i in begin...end) {
			var e = events[i];

			if (e.timelineIndex >= minTimelineIndex && e.timelineIndex < maxTimelineIndex) {
				var arrowIndex = 0;

				x = e.step * sizeX;
				y = e.timelineIndex * sizeY;

				if (e.time != null && e.time > 0) {
					var sus = (e.value > e.lastValue ? easeSpritesUp[e.easeIndex] : easeSpritesDown[e.easeIndex]);
					arrowIndex = e.value > e.lastValue ? 2 : 1;
					sus.x = this.x;
					sus.y = this.y;
					sus.scale.set((e.time*sizeX), sizeY);
					sus.updateHitbox();
					sus.cameras = this.cameras;
					sus.draw();
				}

				var arrow = e.selected ? arrowsSelected[arrowIndex] : arrows[arrowIndex];
				arrow.x = this.x;
				arrow.y = this.y;
				arrow.cameras = this.cameras;
				arrow.draw();
			}
		}
	}
}

















































































































		















