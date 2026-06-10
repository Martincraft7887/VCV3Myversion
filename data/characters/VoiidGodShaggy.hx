

var targetX = 400;
var targetY = 950;

var count = 50;

function update(elapsed)
{
    
    count = count + (50*elapsed);
	var what = count / 6;
    //x += 100*elapsed;

    x = targetX + Math.cos(what / 7) * 20;
    y = targetY + Math.cos(what / 5) * 40;
}
