#pragma header

uniform sampler2D bg;
uniform sampler2D prevBG;
uniform float fade;
uniform float lockStaticTime;
uniform float lockStaticStrength;

float lockRand(vec2 p)
{
	return fract(sin(dot(p, vec2(12.9898, 78.233)) + lockStaticTime * 39.71) * 43758.5453123);
}

vec3 lockStatic(vec2 uv, vec3 base)
{
	float noise = lockRand(floor(uv * vec2(360.0, 210.0)));
	float fineNoise = lockRand(floor(uv * vec2(960.0, 540.0)) + vec2(lockStaticTime * 95.0, 0.0));
	float scanline = sin((uv.y + lockStaticTime * 0.18) * 980.0) * 0.08;
	float rollingBand = smoothstep(0.0, 0.04, abs(fract(uv.y * 2.2 - lockStaticTime * 0.35) - 0.5));
	rollingBand = (1.0 - rollingBand) * 0.25;
	float value = clamp(noise * 0.7 + fineNoise * 0.25 + scanline + rollingBand, 0.0, 1.0);
	return mix(base, vec3(value), clamp(lockStaticStrength, 0.0, 1.0));
}

void main()
{
	vec2 uv = openfl_TextureCoordv;
	vec4 bgCol = mix(flixel_texture2D(bg, uv), flixel_texture2D(prevBG, uv), fade);
	if (lockStaticStrength > 0.001)
		bgCol.rgb = lockStatic(uv, bgCol.rgb);
	gl_FragColor = flixel_texture2D(bitmap, uv) * bgCol;
}
