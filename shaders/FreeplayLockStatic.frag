#pragma header

uniform float iTime;
uniform float strength;
uniform float overlayOnly;

float rand(vec2 p)
{
	return fract(sin(dot(p, vec2(12.9898, 78.233)) + iTime * 38.17) * 43758.5453123);
}

void main()
{
	vec2 uv = openfl_TextureCoordv;
	vec2 cell = floor(uv * vec2(360.0, 210.0));

	float noise = rand(cell);
	float fineNoise = rand(floor(uv * vec2(960.0, 540.0)) + vec2(iTime * 90.0, 0.0));
	float scanline = sin((uv.y + iTime * 0.18) * 980.0) * 0.08;
	float rollingBand = smoothstep(0.0, 0.04, abs(fract(uv.y * 2.2 - iTime * 0.35) - 0.5));
	rollingBand = (1.0 - rollingBand) * 0.28;
	float dropout = step(0.982, rand(vec2(floor(uv.y * 80.0), floor(iTime * 20.0)))) * 0.45;

	float value = clamp(noise * 0.7 + fineNoise * 0.25 + scanline + rollingBand + dropout, 0.0, 1.0);
	float mixStrength = clamp(strength, 0.0, 1.0);

	if (overlayOnly > 0.5)
	{
		float alpha = mixStrength * (0.22 + value * 0.55);
		gl_FragColor = vec4(vec3(value), alpha);
		return;
	}

	vec4 base = flixel_texture2D(bitmap, uv);
	vec3 staticColor = vec3(value);
	vec3 color = mix(base.rgb * 0.55, staticColor, mixStrength * 0.75);
	gl_FragColor = vec4(color, base.a);
}
