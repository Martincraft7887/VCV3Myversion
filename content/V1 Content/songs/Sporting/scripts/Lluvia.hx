import openfl.filters.ShaderFilter;
var rainEnabled:Bool = false;
var rainApplied:Bool = false;
var rainShader:CustomShader;
var rainFilter:ShaderFilter;

function postCreate() {

    rainShader = new CustomShader("RainEffect");
    rainFilter = new ShaderFilter(rainShader);

    rainShader.hset("iTime", 0);

    camGame.setFilters([]);
    camHUD.setFilters([]);
    camOther.setFilters([]);
}

function update(elapsed:Float) {
    if (!rainEnabled && !rainApplied) return;

    // solo cambia filtros cuando cambia el estado
    if (rainEnabled && !rainApplied) {

        camGame.setFilters([rainFilter]);
        camHUD.setFilters([rainFilter]);
        camOther.setFilters([rainFilter]);

        rainApplied = true;

    } else if (!rainEnabled && rainApplied) {

        camGame.setFilters([]);
        camHUD.setFilters([]);
        camOther.setFilters([]);

        rainApplied = false;
    }

    if (rainApplied)
        rainShader.hset("iTime", Conductor.songPosition / 1000);
}

function stepHit() {

    if (curStep == -8) rainEnabled = false;
    if (curStep == 512) rainEnabled = true;
    if (curStep == 768) rainEnabled = false;
    if (curStep == 1280) rainEnabled = true;
    if (curStep == 1536) rainEnabled = false;
    if (curStep == 2048) rainEnabled = true;
    if (curStep == 2080) rainEnabled = false;
    if (curStep == 2336) rainEnabled = true;
    if (curStep == 2464) rainEnabled = false;
    if (curStep == 2468) rainEnabled = true;
    if (curStep == 2592) rainEnabled = false;
    if (curStep == 2856) rainEnabled = true;
    if (curStep == 2864) rainEnabled = false;

}
