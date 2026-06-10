import flixel.FlxSprite;

var vShader = null;
var vortex:FlxSprite = null;

function createVortex()
{
	if (vortex != null)
	{
		remove(vortex, true);
		vortex.destroy();
	}

	vShader = new CustomShader("VortexEffect");
	vShader.spiralColor = [2.5 * 0.7, 1.0 * 0.7, 1.5 * 0.7];

	vortex = new FlxSprite(-900, -1400);
	vortex.scrollFactor.set(0.2, 0.2);
	vortex.makeGraphic(1, 1);
	vortex.setGraphicSize(4000, 4000);
	vortex.updateHitbox();
	vortex.shader = vShader;

	insert(0, vortex);
}

function postCreate()
{
	createVortex();
}

function onStageChanged(stageName:String)
{
	createVortex();
}

function postUpdate(elapsed)
{
	if (vShader == null || vortex == null)
		return;

	vShader.iTime = Conductor.songPosition * 0.001 * 3;

	if (colorswapShader != null)
		vShader.hue = colorswapShader.hue;
}