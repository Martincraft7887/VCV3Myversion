import openfl.filters.ShaderFilter;

var rainEnabled:Bool = false;
var rainApplied:Bool = false;

var rainShader:CustomShader;
var rainFilter:ShaderFilter;

function postCreate() {

    rainShader = new CustomShader("RainEffect");
    rainFilter = new ShaderFilter(rainShader);

    rainShader.hset("iTime", 0);
}

function onEvent(event) {
    if (event.event.name != "Rain Toggle") return;
    rainEnabled = event.event.params[0];
}

function addRainFilter(cam) {

    var filters = cam.filters;
    if (filters == null) filters = [];

    // Evita duplicarlo
    if (!filters.contains(rainFilter)) {
        filters.push(rainFilter);
        cam.setFilters(filters);
    }
}

function removeRainFilter(cam) {

    var filters = cam.filters;
    if (filters == null) return;

    filters.remove(rainFilter);
    cam.setFilters(filters);
}

function update(elapsed:Float) {

    rainShader.hset("iTime", Conductor.songPosition / 1000);

    if (rainEnabled && !rainApplied) {

        addRainFilter(camGame);
        addRainFilter(camHUD);

        rainApplied = true;

    } else if (!rainEnabled && rainApplied) {

        removeRainFilter(camGame);
        removeRainFilter(camHUD);

        rainApplied = false;
    }
}