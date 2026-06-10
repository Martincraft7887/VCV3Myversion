import flixel.text.FlxTextBorderStyle;
import funkin.game.PlayState;

var popupCombo:Int = 0;
var popupScale:Float = 0.5;
var popupSpacing:Int = 5;
var krazyWindowMs:Float = 25; // Ventana "perfecta" para Krazy
var ratingCounterTxt:FlxText;

var countKrazy:Int = 0;
var countSick:Int = 0;
var countGood:Int = 0;
var countBad:Int = 0;
var countShit:Int = 0;
var lastEngineMisses:Int = -1;

var fadeTimer:Float = 0;
var centerY:Float = (FlxG.height * 0.45); 
var disabledSongs = [
    "final destination vip",
    "rejected vip"
];

function isDisabledSong():Bool
{
    return curSong != null && disabledSongs.contains(curSong.toLowerCase());
}

function postCreate() {
if (isDisabledSong()) return;
ratingCounterTxt = new FlxText(0, 0, 220, "");

ratingCounterTxt.setFormat(
    Paths.font("Contb___.ttf"),
    16,
    FlxColor.WHITE,
    "left",
    FlxTextBorderStyle.OUTLINE,
    FlxColor.BLACK
);

ratingCounterTxt.borderSize = 2;
ratingCounterTxt.borderQuality = 2;
ratingCounterTxt.scrollFactor.set();
ratingCounterTxt.cameras = [camHUD];
ratingCounterTxt.alpha = 0; // empieza invisible
add(ratingCounterTxt);

// izquierda centrado vertical
ratingCounterTxt.x = 20;
ratingCounterTxt.y = (FlxG.height / 2) - 70;

}


function onPlayerHit(e) {
    if (isDisabledSong()) return;
    e.showRating = false;
    if (e.note.isSustainNote) return;

    popupCombo++;

    // Usar el rating que ya calcula el engine para evitar desincronías por hitWindow local.
    var rating:String = e.rating;
    if (rating == null) rating = "sick";

    // "Krazy" solo en hits muy centrados; si no, Sick se queda como Sick.
    if (rating == "sick" && e.note != null) {
        var hitDiffMs = Math.abs(Conductor.songPosition - e.note.strumTime);
        if (hitDiffMs <= krazyWindowMs) rating = "krazy";
    }

    // Fallback por si llega un rating custom del engine.
    if (rating != "krazy" && rating != "sick" && rating != "good" && rating != "bad" && rating != "shit") {
        rating = "sick";
    }

    showPopupRating(rating, popupCombo);

switch(rating)
{
    case "krazy": countKrazy++;
    case "sick": countSick++;
    case "good": countGood++;
    case "bad": countBad++;
    case "shit": countShit++;
}

updateRatingCounter();
showCounter();
}

function onPlayerMiss(e) {
    // Intencionalmente vacío:
    // los misses/combobreak se leen directamente de PlayState.misses en update().
}

function getShaderFloat(shader:Dynamic, name:String, fallback:Float = 0):Float {
    if (shader == null) return fallback;

    try {
        var value = Reflect.getProperty(shader, name);
        if (value == null) value = Reflect.field(shader, name);
        if (value == null) return fallback;

        var parsed = Std.parseFloat(Std.string(value));
        return Math.isNaN(parsed) ? fallback : parsed;
    } catch(e:Dynamic) {
        return fallback;
    }
}

function getVisualStrumCenterX(strum:Dynamic):Float {
    if (strum == null) return FlxG.width * 0.5;

    var center = strum.x + (strum.width * 0.5);
    var shader = Reflect.field(strum, "shader");

    if (shader != null) {
        var shaderCenter = getShaderFloat(shader, "screenX", Math.NaN);
        if (!Math.isNaN(shaderCenter)) center = shaderCenter;

        try {
            var offset = scripts.call("getNoteModifierVisualOffsetX", [1, strum.ID, center]);
            if (offset != null) center += offset;
        } catch(e:Dynamic) {}
    }

    return center;
}

function getPlayerStrumlineCenterX():Float {
    try {
        var line = strumLines.members[1];
        if (line == null || line.members == null || line.members.length < 1)
            return FlxG.width * 0.5;

        var minX = Math.POSITIVE_INFINITY;
        var maxX = Math.NEGATIVE_INFINITY;
        for (strum in line.members) {
            if (strum == null) continue;
            var center = getVisualStrumCenterX(strum);
            var halfWidth = strum.width * 0.5;
            minX = Math.min(minX, center - halfWidth);
            maxX = Math.max(maxX, center + halfWidth);
        }

        if (minX != Math.POSITIVE_INFINITY && maxX != Math.NEGATIVE_INFINITY)
            return (minX + maxX) * 0.5;
    } catch(e:Dynamic) {}

    return FlxG.width * 0.5;
}

function showPopupRating(rating:String, combo:Int) {
    if (isDisabledSong()) return;
    var ratingSprite:FlxSprite = new FlxSprite();
    ratingSprite.loadGraphic(Paths.image("game/score/" + rating));
    ratingSprite.cameras = [camHUD];
    
    ratingSprite.scale.set(popupScale * 1.2, popupScale * 1.2); 
    ratingSprite.updateHitbox();
    
    var centerX = FlxG.width * 0.5;
    ratingSprite.x = centerX - (ratingSprite.width * 0.5);
    ratingSprite.y = centerY - (ratingSprite.height / 2); 
    
    ratingSprite.alpha = 0;

    // INSERTAR AL FINAL para que se dibuje sobre los anteriores
    add(ratingSprite); 

    FlxTween.tween(ratingSprite, {
        alpha: 1,
        'scale.x': popupScale,
        'scale.y': popupScale
    }, 0.08, {ease: FlxEase.backOut});

    // Movimiento hacia ARRIBA (para que no tape lo que viene) o hacia abajo
    // Si quieres que los nuevos NO sean tapados, los viejos deben caer rápido
    FlxTween.tween(ratingSprite, {
        y: ratingSprite.y - 20, // Cambiado a subir un poco
        alpha: 0
    }, 0.25, {
        startDelay: 0.4,
        ease: FlxEase.quadIn,
        onComplete: (_) -> ratingSprite.destroy()
    });

    showCombo(combo, (centerY + 65), centerX);
}

function showCombo(value:Int, startY:Float, centerX:Float) {
    if (isDisabledSong()) return;
    var digits = Std.string(value).split("");
    var numbers:Array<FlxSprite> = [];

    for (d in digits) {
        var s = new FlxSprite();
        s.loadGraphic(Paths.image("game/score/num" + d));
        s.scale.set(popupScale, popupScale);
        s.updateHitbox();
        s.cameras = [camHUD];
        numbers.push(s);
    }

    var totalWidth:Float = 0;
    for (n in numbers) totalWidth += n.width + popupSpacing;
    totalWidth -= popupSpacing;

    var startX = centerX - (totalWidth / 2);

    for (n in numbers) {
        n.x = startX;
        n.y = startY; 
        n.alpha = 0;
        
        add(n);

        FlxTween.tween(n, {alpha: 1}, 0.08);

        FlxTween.tween(n, {
            y: n.y + 20,
            alpha: 0
        }, 0.25, {
            startDelay: 0.4,
            ease: FlxEase.quadIn,
            onComplete: (_) -> n.destroy()
        });

        startX += n.width + popupSpacing;
    }
}

function updateRatingCounter()
{
    ratingCounterTxt.text =
        "Krazy: " + countKrazy + "\n" +
        "Sick:  " + countSick + "\n" +
        "Good:  " + countGood + "\n" +
        "Bad:   " + countBad + "\n" +
        "Shit:  " + countShit + "\n" +
        "Skill Issues:  " + (PlayState.instance != null ? PlayState.instance.misses : 0);
}

function showCounter()
{
    if (isDisabledSong()) return;
    ratingCounterTxt.alpha = 0.8; // aparece
    fadeTimer = 2.0; // visible por 2 segundos
}

function update(elapsed) {
    if (isDisabledSong()) return;
    // Usar exactamente el mismo contador real que scores.hx (ps.misses).
    var ps = PlayState.instance;
    if (ps != null) {
        if (lastEngineMisses < 0) lastEngineMisses = ps.misses;

        // Solo cuando suben los misses reales: mostrar contador y romper popup combo.
        if (ps.misses > lastEngineMisses) {
            popupCombo = 0;
            updateRatingCounter();
            showCounter();
        } else if (ps.misses < lastEngineMisses) {
            // Reinicios/reintentos.
            updateRatingCounter();
        } else if (ratingCounterTxt.text == "") {
            // Inicializar texto al entrar.
            updateRatingCounter();
        }

        if (ps.misses != lastEngineMisses) {
            lastEngineMisses = ps.misses;
        }
    }

    if (fadeTimer > 0)
{
    fadeTimer -= elapsed;
    if (fadeTimer <= 0)
    {
        FlxTween.tween(ratingCounterTxt, {alpha: 0}, 0.4);
    }
}
}
