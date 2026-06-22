var sound: Sound;

function create()
    sound = Paths.sound('randoms/random-' + FlxG.random.int(0, 46));

function stepHit (curStep: Int) {
    if(curStep != 1) return;

    FlxG.sound.music.volume = 0.2;
    FlxG.sound.play(sound, 1, false, null, true, function()
    {
        if (!isEnding)
            FlxG.sound.music.fadeIn(4, 0.2, 1);
    });
}