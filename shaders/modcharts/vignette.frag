#pragma header
uniform float strength;
uniform float size;
uniform float red;
uniform float green;
uniform float blue;
uniform bool followAlpha;

void main() {
	vec2 uv = clamp(openfl_TextureCoordv, vec2(0.0), vec2(1.0));
	vec4 color = flixel_texture2D(bitmap, uv);

	if (strength > 0.0 && size > 0.0) {
		float exponent = max((size * strength) / 12.0, 0.0001);
		vec2 wave = max(sin(uv * 3.0), vec2(0.0001));
		float vignette = clamp(pow(wave.x, exponent) * pow(wave.y, exponent), 0.0, 1.0);
		vec3 vignetteColor = clamp(vec3(red, green, blue) / 255.0, vec3(0.0), vec3(1.0));

		color.rgb = mix(vignetteColor, color.rgb, vignette);
		if (!followAlpha) color.a = clamp(color.a + (1.0 - vignette), 0.0, 1.0);
	}

	gl_FragColor = color;
}
