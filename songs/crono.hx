import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import funkin.backend.system.Conductor;
import funkin.game.PlayState;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Rectangle;

var countdownTxt:FlxText;
var countdownRing:FlxSprite;

var nextNoteTime:Float = -1;
var currentGapMs:Float = 0;
var playerNoteTimes:Array<Float> = [];
var nextNoteIndex:Int = 0;
var lastShownSecond:Int = -999;

var minSpawnGapMs:Float = 3000; // < 4s entre spawns: oculto | >= 4s: visible
var fontSize:Int = 30;
var ringSize:Int = 100;
var ringLineThickness:Int = 15;
var hudYRatio:Float = 0.15;

function postCreate()
{
    countdownRing = new FlxSprite();
    countdownRing.scrollFactor.set();
    countdownRing.cameras = [PlayState.instance.camHUD];
    countdownRing.visible = false;
    add(countdownRing);

    countdownTxt = new FlxText(0, 0, FlxG.width, "", fontSize);
    countdownTxt.setFormat(Paths.font("vcr.ttf"), fontSize, FlxColor.WHITE, "center");
    countdownTxt.scrollFactor.set();
    countdownTxt.cameras = [PlayState.instance.camHUD];
    countdownTxt.alpha = 0;
    add(countdownTxt);

    layoutCountdownHud();
    buildPlayerNoteTimes();
    refreshNextNoteTime();
}

function layoutCountdownHud()
{
    var centerX = FlxG.width * 0.5;
    var centerY = FlxG.height * hudYRatio;

    countdownRing.x = centerX - (ringSize * 0.5);
    countdownRing.y = centerY - (ringSize * 0.5);

    countdownTxt.y = centerY - (fontSize * 0.45);
    countdownTxt.screenCenter(FlxAxes.X);
}

/** Precalcula tiempos del chart (1 vez). */
function buildPlayerNoteTimes()
{
    playerNoteTimes = [];
    nextNoteIndex = 0;

    var ps = PlayState.instance;
    if (ps == null || ps.playerStrums == null || SONG == null || SONG.strumLines == null) return;

    var lineIndex = ps.playerStrums.ID;
    if (lineIndex < 0 || lineIndex >= SONG.strumLines.length) return;

    var chartLine = SONG.strumLines[lineIndex];
    if (chartLine.notes == null) return;

    var lastTime:Float = -1;
    for (note in chartLine.notes)
    {
        if (note == null) continue;
        if (note.time == lastTime) continue;
        lastTime = note.time;
        playerNoteTimes.push(note.time);
    }

    playerNoteTimes.sort(function(a:Float, b:Float):Int {
        if (a < b) return -1;
        if (a > b) return 1;
        return 0;
    });
}

function refreshNextNoteTime()
{
    var songPos = Conductor.songPosition;

    while (nextNoteIndex < playerNoteTimes.length && playerNoteTimes[nextNoteIndex] <= songPos)
        nextNoteIndex++;

    if (nextNoteIndex < playerNoteTimes.length)
    {
        nextNoteTime = playerNoteTimes[nextNoteIndex];

        if (nextNoteIndex > 0)
            currentGapMs = playerNoteTimes[nextNoteIndex] - playerNoteTimes[nextNoteIndex - 1];
        else
            currentGapMs = playerNoteTimes[nextNoteIndex]; // primera nota: desde inicio
    }
    else
    {
        nextNoteTime = -1;
        currentGapMs = 0;
    }
}

function hasEnoughSpawnGap():Bool
{
    return currentGapMs >= minSpawnGapMs;
}

function shouldShowCountdown(timeLeftSec:Float):Bool
{
    if (!hasEnoughSpawnGap()) return false;
    return timeLeftSec > 0;
}

function drawCountdownRing(progress:Float)
{
    if (progress <= 0)
    {
        countdownRing.visible = false;
        return;
    }

    var bmp = new BitmapData(ringSize, ringSize, true, 0x00000000);
    var shape = new Shape();
    shape.graphics.lineStyle(ringLineThickness, 0xFFFFFFFF, 1);

    var cx = ringSize * 0.5;
    var cy = ringSize * 0.5;
    var radius = (ringSize * 0.5) - (ringLineThickness + 2);

    var startAngle = -Math.PI * 0.5;
    var sweep = Math.PI * 2 * progress;
    var segments = Std.int(48 * progress) + 2;

    shape.graphics.moveTo(
        cx + Math.cos(startAngle) * radius,
        cy + Math.sin(startAngle) * radius
    );

    for (i in 1...segments)
    {
        var t = i / (segments - 1);
        var angle = startAngle + sweep * t;
        shape.graphics.lineTo(
            cx + Math.cos(angle) * radius,
            cy + Math.sin(angle) * radius
        );
    }

    bmp.draw(shape);
    countdownRing.loadGraphic(FlxGraphic.fromBitmapData(bmp), false, ringSize, ringSize);
    countdownRing.visible = true;
}

function hideCountdown()
{
    countdownTxt.alpha = 0;
    countdownRing.visible = false;
    lastShownSecond = -999;
}

function update(elapsed:Float)
{
    var ps = PlayState.instance;
    if (ps == null || ps.playerStrums == null) return;

    refreshNextNoteTime();

    if (nextNoteTime < 0)
    {
        hideCountdown();
        return;
    }

    var timeLeftSec:Float = (nextNoteTime - Conductor.songPosition) / 1000;

    if (!shouldShowCountdown(timeLeftSec))
    {
        hideCountdown();
        return;
    }

    // Texto dinámico con el segundo actual
    var whole:Int = Math.ceil(timeLeftSec);

    if (whole != lastShownSecond)
    {
        lastShownSecond = whole;
        countdownTxt.text = Std.string(whole);
        countdownTxt.screenCenter(FlxAxes.X);
    }

    // Nueva lógica para el círculo:
    // El progreso se calcula dinámicamente según el tamaño total de la sección de descanso (gap)
    var totalGapSec:Float = currentGapMs / 1000;
    var ringProgress:Float = 1.0;

    if (totalGapSec > 0)
    {
        ringProgress = timeLeftSec / totalGapSec;
    }

    // Aseguramos que el valor esté estrictamente entre 0.0 y 1.0
    if (ringProgress > 1) ringProgress = 1;
    if (ringProgress < 0) ringProgress = 0;

    countdownTxt.alpha = 1.0; 
    drawCountdownRing(ringProgress);
}