#pragma header

uniform float iTime;
uniform float intensity;
uniform float fireSpeed;
uniform float fireScale;
uniform float coverage;
uniform float charAmount;

uniform vec3 coreColor;
uniform vec3 midColor;
uniform vec3 outerColor;

float fireHash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float fireNoise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	local = local * local * (3.0 - 2.0 * local);

	float a = fireHash(cell);
	float b = fireHash(cell + vec2(1.0, 0.0));
	float c = fireHash(cell + vec2(0.0, 1.0));
	float d = fireHash(cell + vec2(1.0, 1.0));

	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

float fireFBM(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;

	for (int octave = 0; octave < 4; ++octave) {
		value += fireNoise(p) * amplitude;
		p = mat2(1.62, 1.18, -1.18, 1.62) * p + vec2(4.7, 2.9);
		amplitude *= 0.5;
	}

	return value;
}

vec3 getFireColor(float heat) {
	vec3 color = mix(outerColor, midColor, smoothstep(0.12, 0.68, heat));
	return mix(color, coreColor, smoothstep(0.62, 1.0, heat));
}

void main() {
	vec2 uv = openfl_TextureCoordv.xy;
	vec4 source = flixel_texture2D(bitmap, uv);

	if (intensity <= 0.001 || source.a <= 0.001) {
		gl_FragColor = source;
		return;
	}
	vec3 sourceColor = source.rgb / max(source.a, 0.0001);

	vec2 textureSize = max(openfl_TextureSize.xy, vec2(1.0));
	vec2 pixel = uv * textureSize;
	vec2 texel = 1.0 / textureSize;
	float safeScale = max(fireScale, 0.05);
	float time = iTime * max(fireSpeed, 0.0);

	// Two noise layers moving upward create broad flames and small flickering tips.
	vec2 broadUV = vec2(pixel.x / (44.0 * safeScale), pixel.y / (62.0 * safeScale) + time * 1.35);
	float horizontalWarp = (fireFBM(broadUV * 0.58 + vec2(2.1, time * 0.22)) - 0.5) * 1.7;
	broadUV.x += horizontalWarp;

	float broad = fireFBM(broadUV);
	float detail = fireFBM(broadUV * 2.23 + vec2(7.4, time * 1.15));
	float tongues = sin(broadUV.x * 4.2 + broad * 5.0 - time * 2.1) * 0.5 + 0.5;
	float field = broad * 0.66 + detail * 0.27 + tongues * 0.12;

	float amount = clamp(coverage, 0.0, 1.0);
	float threshold = mix(0.86, 0.28, amount);
	float heat = smoothstep(threshold - 0.12, threshold + 0.12, field);

	// A one-pixel alpha test makes exposed edges ignite without coloring the
	// transparent rectangle around the sprite.
	float nearbyAlpha = min(
		min(flixel_texture2D(bitmap, uv + vec2(texel.x, 0.0)).a,
			flixel_texture2D(bitmap, uv - vec2(texel.x, 0.0)).a),
		min(flixel_texture2D(bitmap, uv + vec2(0.0, texel.y)).a,
			flixel_texture2D(bitmap, uv - vec2(0.0, texel.y)).a)
	);
	float edge = clamp((source.a - nearbyAlpha) * 2.5, 0.0, 1.0);
	float edgeFlicker = 0.45 + 0.55 * fireFBM(broadUV * 1.45 + vec2(-3.0, time));
	heat = max(heat, edge * edgeFlicker);

	float strength = max(intensity, 0.0);
	float blendAmount = clamp(heat * strength, 0.0, 1.0);
	float soot = clamp(charAmount, 0.0, 1.0) * (1.0 - heat * 0.72) * min(strength, 1.0);
	vec3 charred = mix(sourceColor, sourceColor * mix(0.24, 0.07, broad), soot);

	vec3 fireColor = getFireColor(heat);
	float overbright = 1.0 + max(strength - 1.0, 0.0) * 0.65;
	vec3 emissive = fireColor * (0.82 + heat * 0.72) * overbright + sourceColor * 0.12;
	vec3 result = mix(charred, emissive, blendAmount);

	// The original alpha is preserved, so transparent sprites do not turn into
	// visible rectangles and animated atlas frames remain safe to use.
	gl_FragColor = vec4(result * source.a, source.a);
}
