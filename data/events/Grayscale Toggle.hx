var grayscale:Bool = false;

var bfShader:CustomShader;
var dadShader:CustomShader;
var gfShader:CustomShader;
var stageShader:CustomShader;

var bfStrength:Float = 1;
var dadStrength:Float = 1;
var gfStrength:Float = 1;
var stageStrength:Float = 1;

var bfSingTimer:Float = 0;
var dadSingTimer:Float = 0;
var gfSingTimer:Float = 0;

var singHoldTime:Float = Conductor.stepCrochet * 4 / 1000;
var fadeSpeed:Float = 4;

function postCreate() {

    stageShader = new CustomShader("GreyscaleEffect");
    stageShader.hset("strength", 1);

    for (name => spr in stage.stageSprites) {
        spr.shader = stageShader;
    }

    bfShader = new CustomShader("GreyscaleEffect");
    dadShader = new CustomShader("GreyscaleEffect");
    gfShader = new CustomShader("GreyscaleEffect");

    bfShader.hset("strength", 1);
    dadShader.hset("strength", 1);
    gfShader.hset("strength", 1);

    if (boyfriend != null) boyfriend.shader = bfShader;
    if (dad != null) dad.shader = dadShader;
    if (gf != null) gf.shader = gfShader;
}

function onEvent(event) {
    if (event.event.name != "Grayscale Toggle") return;

    var enable = event.event.params[0];
    grayscale = enable;
}

function isSinging(char):Bool {
    return char != null
        && char.animation != null
        && char.animation.curAnim != null
        && char.animation.curAnim.name.indexOf("sing") != -1;
}

function lerp(a:Float, b:Float, t:Float):Float {
    return a + (b - a) * t;
}

function update(elapsed) {

    for (name => spr in stage.stageSprites) {
        spr.shader = stageShader;
    }

    if (!grayscale) {

        stageStrength = lerp(stageStrength, 0, elapsed * fadeSpeed);

        bfStrength = lerp(bfStrength, 0, elapsed * fadeSpeed);
        dadStrength = lerp(dadStrength, 0, elapsed * fadeSpeed);
        gfStrength = lerp(gfStrength, 0, elapsed * fadeSpeed);

    } else {

        stageStrength = lerp(stageStrength, 1, elapsed * fadeSpeed);

        if (isSinging(boyfriend)) bfSingTimer = singHoldTime;
        else bfSingTimer -= elapsed;

        var bfTarget = (bfSingTimer > 0) ? 0 : 1;
        bfStrength = lerp(bfStrength, bfTarget, elapsed * fadeSpeed);

        if (isSinging(dad)) dadSingTimer = singHoldTime;
        else dadSingTimer -= elapsed;

        var dadTarget = (dadSingTimer > 0) ? 0 : 1;
        dadStrength = lerp(dadStrength, dadTarget, elapsed * fadeSpeed);

        if (gf != null) {
            if (isSinging(gf)) gfSingTimer = singHoldTime;
            else gfSingTimer -= elapsed;

            var gfTarget = (gfSingTimer > 0) ? 0 : 1;
            gfStrength = lerp(gfStrength, gfTarget, elapsed * fadeSpeed);
        }
    }

    stageShader.hset("strength", stageStrength);
    bfShader.hset("strength", bfStrength);
    dadShader.hset("strength", dadStrength);
    if (gf != null) gfShader.hset("strength", gfStrength);
}