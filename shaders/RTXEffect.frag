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
uniform float innerShadowAngle0;
uniform float innerShadowAngle1;
uniform float innerShadowAngle2;
uniform float innerShadowAngle3;
uniform vec4 overlayColor0;
uniform vec4 overlayColor1;
uniform vec4 overlayColor2;
uniform vec4 overlayColor3;
uniform vec4 satinColor0;
uniform vec4 satinColor1;
uniform vec4 satinColor2;
uniform vec4 satinColor3;
uniform vec4 innerShadowColor0;
uniform vec4 innerShadowColor1;
uniform vec4 innerShadowColor2;
uniform vec4 innerShadowColor3;
uniform float innerShadowDistance0;
uniform float innerShadowDistance1;
uniform float innerShadowDistance2;
uniform float innerShadowDistance3;
uniform float layernumbers0;
uniform float layernumbers1;
uniform float layernumbers2;
uniform float layernumbers3;
uniform float layerseparation0;
uniform float layerseparation1;
uniform float layerseparation2;
uniform float layerseparation3;
uniform float pointLightCount;
uniform float innerShadowDistance;
uniform float layernumbers;
uniform float layerseparation;
uniform float hue;

const int MAX_LAYERS = 32;
const int MAX_POINT_LIGHTS = 4;

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

vec4 getOverlayColor(int light) {
	if (light == 0) return overlayColor0;
	if (light == 1) return overlayColor1;
	if (light == 2) return overlayColor2;
	if (light == 3) return overlayColor3;
	return overlayColor;
}

vec4 getSatinColor(int light) {
	if (light == 0) return satinColor0;
	if (light == 1) return satinColor1;
	if (light == 2) return satinColor2;
	if (light == 3) return satinColor3;
	return satinColor;
}

vec4 getInnerColor(int light) {
	if (light == 0) return innerShadowColor0;
	if (light == 1) return innerShadowColor1;
	if (light == 2) return innerShadowColor2;
	if (light == 3) return innerShadowColor3;
	return innerShadowColor;
}

float getInnerDistance(int light) {
	if (light == 0) return innerShadowDistance0;
	if (light == 1) return innerShadowDistance1;
	if (light == 2) return innerShadowDistance2;
	if (light == 3) return innerShadowDistance3;
	return innerShadowDistance;
}

float getLayerNumbers(int light) {
	if (light == 0) return layernumbers0;
	if (light == 1) return layernumbers1;
	if (light == 2) return layernumbers2;
	if (light == 3) return layernumbers3;
	return layernumbers;
}

float getLayerSeparation(int light) {
	if (light == 0) return layerseparation0;
	if (light == 1) return layerseparation1;
	if (light == 2) return layerseparation2;
	if (light == 3) return layerseparation3;
	return layerseparation;
}

void main() {
	vec2 uv = openfl_TextureCoordv.xy;
	vec4 spritecolor = flixel_texture2D(bitmap, uv);
	vec4 shiftedOverlay = vec4(shiftHue(overlayColor.rgb), overlayColor.a);
	vec4 shiftedSatin = vec4(shiftHue(satinColor.rgb), satinColor.a);
	float activeLights = max(pointLightCount, 1.0);

	if (pointLightCount <= 0.0)
		spritecolor.rgb = blendMultiply(spritecolor.rgb, shiftedSatin.rgb, shiftedSatin.a);

	for (int light = 0; light < MAX_POINT_LIGHTS; light++) {
		if (float(light) >= activeLights) break;

		vec4 lightSatin = pointLightCount > 0.0 ? getSatinColor(light) : satinColor;
		vec4 lightInner = pointLightCount > 0.0 ? getInnerColor(light) : innerShadowColor;
		lightSatin = vec4(shiftHue(lightSatin.rgb), lightSatin.a);
		lightInner = vec4(shiftHue(lightInner.rgb), lightInner.a);

		if (pointLightCount > 0.0)
			spritecolor.rgb = blendMultiply(spritecolor.rgb, lightSatin.rgb, lightSatin.a / activeLights);

		float sampleDist = clamp(pointLightCount > 0.0 ? getLayerNumbers(light) : layernumbers, 1.0, float(MAX_LAYERS));
		vec2 resFactor = (pointLightCount > 0.0 ? getLayerSeparation(light) : layerseparation) / openfl_TextureSize.xy;
		vec2 distMult = ((pointLightCount > 0.0 ? getInnerDistance(light) : innerShadowDistance) * resFactor) / sampleDist;

		float angle = innerShadowAngle;
		if (pointLightCount > 0.0) {
			if (light == 0) angle = innerShadowAngle0;
			else if (light == 1) angle = innerShadowAngle1;
			else if (light == 2) angle = innerShadowAngle2;
			else if (light == 3) angle = innerShadowAngle3;
		}

		float offsetX = cos(angle);
		float offsetY = sin(angle);

		for (int i = 0; i < MAX_LAYERS; i++) {
			if (float(i) >= sampleDist) break;

			vec2 sampleUV = uv + vec2(offsetX * (distMult.x * float(i)), offsetY * (distMult.y * float(i)));
			vec4 col = texture2D(bitmap, sampleUV);
			spritecolor.rgb = blendColorDodge(spritecolor.rgb, lightInner.rgb, (lightInner.a / activeLights) * inv(col.a));
		}
	}

	if (pointLightCount > 0.0) {
		for (int light = 0; light < MAX_POINT_LIGHTS; light++) {
			if (float(light) >= activeLights) break;
			vec4 lightOverlay = vec4(shiftHue(getOverlayColor(light).rgb), getOverlayColor(light).a);
			spritecolor.rgb = blendLighten(spritecolor.rgb, lightOverlay.rgb, lightOverlay.a / activeLights);
		}
	} else {
		spritecolor.rgb = blendLighten(spritecolor.rgb, shiftedOverlay.rgb, shiftedOverlay.a);
	}
	gl_FragColor = spritecolor * spritecolor.a;
}
