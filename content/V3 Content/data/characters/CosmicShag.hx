

var targetX = 89;
var targetY = 1353;

var count = 60;

function update(elapsed)
{
    
    count = count + (50*elapsed);
	var what = count / 6;
    //x += 100*elapsed;

    x = targetX + Math.cos(what / 7) * 20;
    y = targetY + Math.cos(what / 5) * 40;
}
