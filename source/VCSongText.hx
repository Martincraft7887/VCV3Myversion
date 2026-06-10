import flixel.text.FlxTextBorderStyle;

class VCSongText extends flixel.text.FlxText {

	public var border1Size:Float = 10;
	public var border1Color:FlxColor = 0xFF0000FF;

	public var border2Size:Float = 5;
	public var border2Color:FlxColor = 0xFFFF0000;

	public var borderIterations:Int = 25;

	public var childText:VCSongText;

	override function regenGraphic():Void
	{
		if (textField == null || !_regen)
			return;

		var oldWidth:Int = 0;
		var oldHeight:Int = FlxText.VERTICAL_GUTTER;

		if (graphic != null)
		{
			oldWidth = graphic.width;
			oldHeight = graphic.height;
		}

		var newWidth:Int = Math.ceil(textField.width+((border1Size+border2Size)*5));
		var textfieldHeight = _autoHeight ? textField.textHeight : textField.height;
		var vertGutter = _autoHeight ? FlxText.VERTICAL_GUTTER : 0;
		// Account for gutter
		var newHeight:Int = Math.ceil(textfieldHeight+((border1Size+border2Size)*5)) + vertGutter;

		// prevent text height from shrinking on flash if text == ""
		if (textField.textHeight == 0)
		{
			newHeight = oldHeight;
		}

		if (oldWidth != newWidth || oldHeight != newHeight)
		{
			// Need to generate a new buffer to store the text graphic
			height = newHeight;
			var key:String = FlxG.bitmap.getUniqueKey("text");
			makeGraphic(newWidth, newHeight, FlxColor.TRANSPARENT, false, key);

			if (_hasBorderAlpha)
				_borderPixels = graphic.bitmap.clone();

			if (_autoHeight)
				textField.height = newHeight;

			_flashRect.x = 0;
			_flashRect.y = 0;
			_flashRect.width = newWidth;
			_flashRect.height = newHeight;
		}
		else // Else just clear the old buffer before redrawing the text
		{
			graphic.bitmap.fillRect(_flashRect, FlxColor.TRANSPARENT);
			if (_hasBorderAlpha)
			{
				if (_borderPixels == null)
					_borderPixels = new BitmapData(frameWidth, frameHeight, true);
				else
					_borderPixels.fillRect(_flashRect, FlxColor.TRANSPARENT);
			}
		}

		if (textField != null && textField.text != null && textField.text.length > 0)
		{
			// Now that we've cleared a buffer, we need to actually render the text to it
			copyTextFormat(_defaultFormat, _formatAdjusted);

			_matrix.identity();

			borderColor = border1Color;
			borderSize = border1Size;
			applyBorderStyle();
			applyBorderTransparency();

			borderColor = border2Color;
			borderSize = border2Size;
			applyBorderStyle();
			applyBorderTransparency();
			applyFormats(_formatAdjusted, false);

			drawTextFieldTo(graphic.bitmap);
		}

		_regen = false;
		resetFrame();
	}

	override function drawTextFieldTo(graphic:BitmapData):Void {
		_matrix.translate((border1Size+border2Size)*2, (border1Size+border2Size)*2); // left and up
		graphic.draw(textField, _matrix);
		_matrix.translate(-(border1Size+border2Size)*2, -(border1Size+border2Size)*2); // return to center
	}

	override function applyBorderStyle():Void
	{
		var iterations:Int = Std.int(borderSize * borderQuality);
		if (iterations <= 0)
		{
			iterations = 1;
		}
		var delta:Float = borderSize / iterations;

		// Render an outline around the text
		// (do 8 offset draw calls)
		applyFormats(_formatAdjusted, true);

		var curDelta:Float = delta;
		var graphic:BitmapData = _hasBorderAlpha ? _borderPixels : graphic.bitmap;

		iterations = borderIterations;
		//smooth ass border
		for (i in 0...iterations) {
			var ang = (360/iterations)*i*(Math.PI/180);
			var x = Math.cos(ang)*borderSize;
			var y = Math.sin(ang)*borderSize;
			_matrix.translate(-x, -y);
			drawTextFieldTo(graphic);
			_matrix.translate(x, y);
		}
	}

	override public function draw():Void
	{
		super.draw();
		if (childText != null) {
			childText.cameras = cameras;
			childText.scale.set(scale.x * 0.75, scale.y * 0.75);
			childText.updateHitbox();
			childText.x = x + (width*0.5) - (childText.width*0.45);
			var yOffset = (height*0.5) - (childText.height*0.2);
			if (PlayState.instance != null && PlayState.instance.downscroll) {
				yOffset = 0; //((height*0.5) - (childText.height*0.2)) + childText.height;
			}
			childText.y = y + yOffset;
			childText.draw();
		}
	}
}

var defaultData = '
{
    "vipFont": "Onslaughter.otf",

    "outerBorderTop": "#000000",
    "outerBorderBot": "#000000",
    "midBorderTop": "#c735ff",
    "midBorderBot": "#9466e4",
    "innerBorderTop": "#3f3f3f",
    "innerBorderBot": "#121617"
}';

function createSongText(song:String, size:Float, spacing:Float, ?data = null) {

	var isVIP = false;
	if (StringTools.endsWith(song, " VIP")) {
		isVIP = true;
		song = StringTools.replace(song, " VIP", "");
	}

	var songText = new VCSongText(0,0,0, song.toUpperCase(), size);
	songText.borderStyle = FlxTextBorderStyle.OUTLINE;
	songText.letterSpacing = spacing;
	songText.borderSize = 5;
	if (data.outerBorderSize != null) songText.border1Size = data.outerBorderSize;
	if (data.midBorderSize != null) songText.border2Size = data.midBorderSize;
	if (data.innerBorderSize != null) songText.borderSize = data.innerBorderSize;
	songText.font = Paths.font(data.songFont != null ? data.songFont : "dumbnerd.ttf");
	songText.screenCenter();
	songText.color = 0xFF00FF00;
	songText.antialiasing = true;

	var shader = new CustomShader(data.shader != null ? data.shader : "TextShader");
	songText.shader = shader;

	if (data == null) {
		data = Json.parse(defaultData);
	}

	shader.outerColorTop = getColorArray(data.outerBorderTop, 0);
	shader.outerColorBot = getColorArray(data.outerBorderBot, 0);
	shader.midColorTop = getColorArray(data.midBorderTop, -0.1);
	shader.midColorBot = getColorArray(data.midBorderBot, 0.1);
	shader.diagonalSplit = data.diagonalSplit != null && data.diagonalSplit ? 1 : 0;
	shader.splitAngle = data.splitAngle != null ? data.splitAngle : 45;
	shader.splitSoftness = data.splitSoftness != null ? data.splitSoftness : 0.015;
	shader.splitOffset = data.splitOffset != null ? data.splitOffset : 0;

	shader.leftOuterColorTop = getColorArray(data.leftOuterBorderTop != null ? data.leftOuterBorderTop : data.outerBorderTop, 0);
	shader.leftOuterColorBot = getColorArray(data.leftOuterBorderBot != null ? data.leftOuterBorderBot : data.outerBorderBot, 0);

	shader.leftMidColorTop = getColorArray(data.leftMidBorderTop != null ? data.leftMidBorderTop : data.midBorderTop, -0.1);
	shader.leftMidColorBot = getColorArray(data.leftMidBorderBot != null ? data.leftMidBorderBot : data.midBorderBot, 0.1);

	shader.leftInnerColorTop = getColorArray(data.leftInnerBorderTop != null ? data.leftInnerBorderTop : data.innerBorderTop, -0.3);
	shader.leftInnerColorBot = getColorArray(data.leftInnerBorderBot != null ? data.leftInnerBorderBot : data.innerBorderBot, 0.3);

	shader.rightOuterColorTop = getColorArray(data.rightOuterBorderTop != null ? data.rightOuterBorderTop : data.outerBorderTop, 0);
	shader.rightOuterColorBot = getColorArray(data.rightOuterBorderBot != null ? data.rightOuterBorderBot : data.outerBorderBot, 0);

	shader.rightMidColorTop = getColorArray(data.rightMidBorderTop != null ? data.rightMidBorderTop : data.midBorderTop, -0.1);
	shader.rightMidColorBot = getColorArray(data.rightMidBorderBot != null ? data.rightMidBorderBot : data.midBorderBot, 0.1);

	shader.rightInnerColorTop = getColorArray(data.rightInnerBorderTop != null ? data.rightInnerBorderTop : data.innerBorderTop, -0.3);
	shader.rightInnerColorBot = getColorArray(data.rightInnerBorderBot != null ? data.rightInnerBorderBot : data.innerBorderBot, 0.3);
	shader.mixGap = 2.0;

	shader.strength = 0;
	shader.intensity = 0;

	if (data.mixGap != null) shader.mixGap = data.mixGap;
	if (data.sobelStrength != null) shader.strength = data.sobelStrength;
	if (data.sobelIntensity != null) shader.intensity = data.sobelIntensity;

	if (isVIP) {
		var vipText = new VCSongText(0,0,0, "VIP", size);
		vipText.borderStyle = FlxTextBorderStyle.OUTLINE;
		vipText.letterSpacing = 80;
		vipText.borderSize = 5;
		vipText.font = Paths.font(
			data.vipFont != null ? data.vipFont : "dumbnerd.ttf"
		);
		vipText.screenCenter();
		vipText.color = 0xFF00FF00;
		vipText.antialiasing = true;
		songText.childText = vipText;

		var vipShader = new CustomShader("TextShader");
		vipText.shader = vipShader;

		vipShader.outerColorTop = getColorArray(data.outerBorderTopVIP != null ? data.outerBorderTopVIP : data.outerBorderTop, 0);
		vipShader.outerColorBot = getColorArray(data.outerBorderBotVIP != null ? data.outerBorderBotVIP : data.outerBorderBot, 0);

		vipShader.midColorTop = getColorArray(data.midBorderTopVIP != null ? data.midBorderTopVIP : data.midBorderTop, -0.1);
		vipShader.midColorBot = getColorArray(data.midBorderBotVIP != null ? data.midBorderBotVIP : data.midBorderBot, 0.1);

		vipShader.innerColorTop = getColorArray(data.innerBorderTopVIP != null ? data.innerBorderTopVIP : data.innerBorderTop, -0.3);
		vipShader.innerColorBot = getColorArray(data.innerBorderBotVIP != null ? data.innerBorderBotVIP : data.innerBorderBot, 0.3);

		vipShader.diagonalSplit = 0;
		vipShader.splitAngle = 45;
		vipShader.splitSoftness = 0.015;
		vipShader.splitOffset = 0;

		vipShader.leftOuterColorTop = getColorArray(data.outerBorderTopVIP != null ? data.outerBorderTopVIP : data.outerBorderTop, 0);
		vipShader.leftOuterColorBot = getColorArray(data.outerBorderBotVIP != null ? data.outerBorderBotVIP : data.outerBorderBot, 0);

		vipShader.leftMidColorTop = getColorArray(data.midBorderTopVIP != null ? data.midBorderTopVIP : data.midBorderTop, -0.1);
		vipShader.leftMidColorBot = getColorArray(data.midBorderBotVIP != null ? data.midBorderBotVIP : data.midBorderBot, 0.1);

		vipShader.leftInnerColorTop = getColorArray(data.innerBorderTopVIP != null ? data.innerBorderTopVIP : data.innerBorderTop, -0.3);
		vipShader.leftInnerColorBot = getColorArray(data.innerBorderBotVIP != null ? data.innerBorderBotVIP : data.innerBorderBot, 0.3);

		vipShader.rightOuterColorTop = vipShader.leftOuterColorTop;
		vipShader.rightOuterColorBot = vipShader.leftOuterColorBot;
		vipShader.rightMidColorTop = vipShader.leftMidColorTop;
		vipShader.rightMidColorBot = vipShader.leftMidColorBot;
		vipShader.rightInnerColorTop = vipShader.leftInnerColorTop;
		vipShader.rightInnerColorBot = vipShader.leftInnerColorBot;
		vipShader.outerColorBot = getColorArray(data.outerBorderBotVIP, 0);
		vipShader.midColorTop = getColorArray(data.midBorderTopVIP, -0.1);
		vipShader.midColorBot = getColorArray(data.midBorderBotVIP, 0.1);
		vipShader.innerColorTop = getColorArray(data.innerBorderTopVIP, -0.3);
		vipShader.innerColorBot = getColorArray(data.innerBorderBotVIP, 0.3);

		vipShader.strength = 0;
		vipShader.intensity = 0;
		vipShader.mixGap = 2.0;
	}

	return songText;
}
function getColorArray(colorString, offset) {
	var col:FlxColor = FlxColor.fromString(colorString);

	var red = (col >> 16) & 0xff;
	var green = (col >> 8) & 0xff;
	var blue = (col) & 0xff;
	
	return [red/255*(1+offset),green/255*(1+offset),blue/255*(1+offset)];
}