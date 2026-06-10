var rainShader:CustomShader;

function create() {
	rainShader = new CustomShader("rain");
	camGame.addShader(rainShader);
}

var localTime:Float = 0;
function update(elapsed:Float) {
localTime += elapsed;
rainShader.iTime = localTime;
rainShader.iIntensity = 0.05;
rainShader.iTimescale = 0.7;
}