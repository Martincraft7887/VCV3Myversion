var enabled:Bool = false;

var bfSobel:CustomShader;
var dadSobel:CustomShader;
var gfSobel:CustomShader;
var stageSobel:CustomShader;

var bfFill:CustomShader;
var dadFill:CustomShader;
var gfFill:CustomShader;

var currentStrength:Float = 0;
var targetStrength:Float = 0;

var fadeSteps:Float = 4;
var fadeSpeed:Float = 1;

var intensity:Float = 1;

function postCreate() {

    // ===== SOBEL (bordes) =====
    stageSobel = new CustomShader("SobelEffect");
    stageSobel.hset("strength", 0);
    stageSobel.hset("intensity", 1);

    for (name => spr in stage.stageSprites) {
        spr.shader = stageSobel;
    }

    bfSobel = new CustomShader("SobelEffect");
    dadSobel = new CustomShader("SobelEffect");
    gfSobel = new CustomShader("SobelEffect");

    bfSobel.hset("strength", 0);
    dadSobel.hset("strength", 0);
    gfSobel.hset("strength", 0);

    bfSobel.hset("intensity", 1);
    dadSobel.hset("intensity", 1);
    gfSobel.hset("intensity", 1);

    // ===== COLOR FILL (negro sólido) =====
    bfFill = new CustomShader("ColorFillEffect");
    dadFill = new CustomShader("ColorFillEffect");
    gfFill = new CustomShader("ColorFillEffect");

    // negro puro
    bfFill.hset("red", 0);
    bfFill.hset("green", 0);
    bfFill.hset("blue", 0);
    bfFill.hset("fade", 0); // IMPORTANTE: 0 = negro completo

    dadFill.hset("red", 0);
    dadFill.hset("green", 0);
    dadFill.hset("blue", 0);
    dadFill.hset("fade", 0);

    gfFill.hset("red", 0);
    gfFill.hset("green", 0);
    gfFill.hset("blue", 0);
    gfFill.hset("fade", 0);

    // aplicar shaders
    if (boyfriend != null) {
        boyfriend.shader = bfFill;
        boyfriend.shader = bfSobel; // Sobel encima
    }

    if (dad != null) {
        dad.shader = dadFill;
        dad.shader = dadSobel;
    }

    if (gf != null) {
        gf.shader = gfFill;
        gf.shader = gfSobel;
    }
}

function onEvent(e) {
    if (e.event.name != "Sobel Effect") return;

    var params = e.event.params;

    enabled = params[0];
    fadeSteps = Math.max(params[1], 1);
    intensity = params[2];

    fadeSpeed = (1 / (fadeSteps * Conductor.stepCrochet / 1000));

    targetStrength = enabled ? 1 : 0;

    // grosor
    stageSobel.hset("intensity", intensity);
    bfSobel.hset("intensity", intensity);
    dadSobel.hset("intensity", intensity);
    gfSobel.hset("intensity", intensity);
}

function lerp(a:Float, b:Float, t:Float):Float {
    return a + (b - a) * t;
}

function update(elapsed) {

    // asegurar que nunca se quite
    for (name => spr in stage.stageSprites) {
        spr.shader = stageSobel;
    }

    if (boyfriend != null) boyfriend.shader = bfSobel;
    if (dad != null) dad.shader = dadSobel;
    if (gf != null) gf.shader = gfSobel;

    currentStrength = lerp(currentStrength, targetStrength, elapsed * fadeSpeed * 10);

    stageSobel.hset("strength", currentStrength);
    bfSobel.hset("strength", currentStrength);
    dadSobel.hset("strength", currentStrength);
    if (gf != null) gfSobel.hset("strength", currentStrength);
}