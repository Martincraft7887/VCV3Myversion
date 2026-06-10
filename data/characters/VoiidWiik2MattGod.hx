

var targetX = 400;
var targetY = 950;

var count = 100;

function update(elapsed)
{
    
    count = count + (50*elapsed);
	var what = count / 6;
    //x += 100*elapsed;

    x = targetX + Math.cos(what / 4) * 20;
    y = targetY + Math.cos(what / 6) * 40;
}
