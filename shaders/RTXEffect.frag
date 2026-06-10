#pragma header

// https://github.com/jamieowen/glsl-blend
float blendOverlay(float base, float blend) {
	return base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend));
}

vec3 blendOverlay(vec3 base, vec3 blend) {
	return vec3(blendOverlay(base.r, blend.r), blendOverlay(base.g, blend.g), blendOverlay(base.b, blend.b));
}

vec3 blendOverlay(vec3 base, vec3 blend, float opacity) {
	return blendOverlay(base, blend) * opacity + base * (1.0 - opacity);
}

float blendColorDodge(float base, float blend) {
	return (blend == 1.0) ? blend : min(base / (1.0 - blend), 1.0);
}

vec3 blendColorDodge(vec3 base, vec3 blend) {
	return vec3(blendColorDodge(base.r, blend.r), blendColorDodge(base.g, blend.g), blendColorDodge(base.b, blend.b));
}

vec3 blendColorDodge(vec3 base, vec3 blend, float opacity) {
	return blendColorDodge(base, blend) * opacity + base * (1.0 - opacity);
}

float blendLighten(float base, float blend) {
	return max(blend, base);
}

vec3 blendLighten(vec3 base, vec3 blend) {
	return vec3(blendLighten(base.r, blend.r), blendLighten(base.g, blend.g), blendLighten(base.b, blend.b));
}

vec3 blendLighten(vec3 base, vec3 blend, float opacity) {
	return blendLighten(base, blend) * opacity + base * (1.0 - opacity);
}

vec3 blendMultiply(vec3 base, vec3 blend) {
	return base * blend;
}

vec3 blendMultiply(vec3 base, vec3 blend, float opacity) {
	return blendMultiply(base, blend) * opacity + base * (1.0 - opacity);
}

float inv(float val) {
	return 1.0 - val;
}

uniform vec4 overlayColor;
uniform vec4 satinColor;
uniform vec4 innerShadowColor;
uniform float innerShadowAngle;
uniform float innerShadowDistance;
uniform float layernumbers;
uniform float layerseparation;
uniform float hue;

const int MAX_LAYERS = 32;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 shiftHue(vec3 color) {
	vec3 hsv = rgb2hsv(color);
	hsv.x += hue;
	return hsv2rgb(hsv);
}

void main() {
	vec2 uv = openfl_TextureCoordv.xy;
	vec4 spritecolor = flixel_texture2D(bitmap, uv);
	float sampleDist = clamp(layernumbers, 1.0, float(MAX_LAYERS));
	vec2 resFactor = layerseparation / openfl_TextureSize.xy;
	vec4 shiftedOverlay = vec4(shiftHue(overlayColor.rgb), overlayColor.a);
	vec4 shiftedSatin = vec4(shiftHue(satinColor.rgb), satinColor.a);
	vec4 shiftedInner = vec4(shiftHue(innerShadowColor.rgb), innerShadowColor.a);

	spritecolor.rgb = blendMultiply(spritecolor.rgb, shiftedSatin.rgb, shiftedSatin.a);

	float offsetX = cos(innerShadowAngle);
	float offsetY = sin(innerShadowAngle);
	vec2 distMult = (innerShadowDistance * resFactor) / sampleDist;

	for (int i = 0; i < MAX_LAYERS; i++) {
		if (float(i) >= sampleDist) break;

		vec2 sampleUV = uv + vec2(offsetX * (distMult.x * float(i)), offsetY * (distMult.y * float(i)));
		vec4 col = texture2D(bitmap, sampleUV);
		spritecolor.rgb = blendColorDodge(spritecolor.rgb, shiftedInner.rgb, shiftedInner.a * inv(col.a));
	}

	spritecolor.rgb = blendLighten(spritecolor.rgb, shiftedOverlay.rgb, shiftedOverlay.a);
	gl_FragColor = spritecolor * spritecolor.a;
}
