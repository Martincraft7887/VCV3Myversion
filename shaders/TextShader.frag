#pragma header
		
uniform vec3 outerColorTop;
uniform vec3 outerColorBot;
uniform vec3 midColorTop;
uniform vec3 midColorBot;
uniform vec3 innerColorTop;
uniform vec3 innerColorBot;

uniform vec3 leftOuterColorTop;
uniform vec3 leftOuterColorBot;
uniform vec3 leftMidColorTop;
uniform vec3 leftMidColorBot;
uniform vec3 leftInnerColorTop;
uniform vec3 leftInnerColorBot;

uniform vec3 rightOuterColorTop;
uniform vec3 rightOuterColorBot;
uniform vec3 rightMidColorTop;
uniform vec3 rightMidColorBot;
uniform vec3 rightInnerColorTop;
uniform vec3 rightInnerColorBot;

uniform float diagonalSplit;
uniform float splitAngle;
uniform float splitSoftness;
uniform float splitOffset;

uniform float strength;
uniform float intensity;
uniform float mixGap;

float getDiagonalSide(vec2 uv)
{
	float ang = radians(splitAngle);
	vec2 p = uv - vec2(0.5, 0.5);

	float d = p.x * cos(ang) + p.y * sin(ang) + splitOffset;

	return smoothstep(-splitSoftness, splitSoftness, d);
}

vec4 getSample(vec2 uv)
{
	vec4 col = flixel_texture2D(bitmap, uv);
	vec4 color = vec4(0.0, 0.0, 0.0, col.a);

	float m = ((uv.y - 0.5) * mixGap) + 0.5;

	vec3 outTop = outerColorTop;
	vec3 outBot = outerColorBot;
	vec3 midTop = midColorTop;
	vec3 midBot = midColorBot;
	vec3 innTop = innerColorTop;
	vec3 innBot = innerColorBot;

	if (diagonalSplit > 0.5)
	{
		float side = getDiagonalSide(uv);

		outTop = mix(leftOuterColorTop, rightOuterColorTop, side);
		outBot = mix(leftOuterColorBot, rightOuterColorBot, side);

		midTop = mix(leftMidColorTop, rightMidColorTop, side);
		midBot = mix(leftMidColorBot, rightMidColorBot, side);

		innTop = mix(leftInnerColorTop, rightInnerColorTop, side);
		innBot = mix(leftInnerColorBot, rightInnerColorBot, side);
	}

	color.rgb += col.r * mix(midTop, midBot, m);
	color.rgb += col.g * mix(innTop, innBot, m);
	color.rgb += col.b * mix(outTop, outBot, m);

	return color;
}

void main()
{
	vec2 uv = openfl_TextureCoordv;
	vec4 col = getSample(uv);

	if (strength <= 0.0)
	{
		gl_FragColor = col;
		return;
	}

	vec2 resFactor = (1.0 / openfl_TextureSize.xy) * intensity;

	vec4 topLeft = getSample(vec2(uv.x - resFactor.x, uv.y - resFactor.y));
	vec4 topMiddle = getSample(vec2(uv.x, uv.y - resFactor.y));
	vec4 topRight = getSample(vec2(uv.x + resFactor.x, uv.y - resFactor.y));

	vec4 midLeft = getSample(vec2(uv.x - resFactor.x, uv.y));
	vec4 midRight = getSample(vec2(uv.x + resFactor.x, uv.y));

	vec4 bottomLeft = getSample(vec2(uv.x - resFactor.x, uv.y + resFactor.y));
	vec4 bottomMiddle = getSample(vec2(uv.x, uv.y + resFactor.y));
	vec4 bottomRight = getSample(vec2(uv.x + resFactor.x, uv.y + resFactor.y));

	vec4 Gx = topLeft + 2.0 * midLeft + bottomLeft - topRight - 2.0 * midRight - bottomRight;
	vec4 Gy = topLeft + 2.0 * topMiddle + topRight - bottomLeft - 2.0 * bottomMiddle - bottomRight;
	vec4 G = sqrt((Gx * Gx) + (Gy * Gy));

	G = col + G;
	G.a = col.a;

	gl_FragColor = mix(col, G, strength);
}