// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
uniform float strength;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
#define texture flixel_texture2D

// third argument fix
vec4 flixel_texture2D(sampler2D bitmap, vec2 coord, float bias) {
	vec4 color = texture2D(bitmap, coord, bias);
	if (!hasTransform) return color;
	if (color.a == 0.0) return vec4(0.0);
	if (!hasColorTransform) return color * openfl_Alphav;

	color = vec4(color.rgb / color.a, color.a);
	mat4 colorMultiplier = mat4(0);
	colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
	colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
	colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
	colorMultiplier[3][3] = openfl_ColorMultiplierv.w;
	color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);

	if (color.a > 0.0)
		return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	
	return vec4(0.0);
}

uniform float iTimeDelta;
uniform float iFrameRate;
uniform int iFrame;
#define iChannelTime float[4](iTime, 0., 0., 0.)
#define iChannelResolution vec3[4](iResolution, vec3(0.), vec3(0.), vec3(0.))
uniform vec4 iMouse;
uniform vec4 iDate;

float random(float x) { return fract(sin(x) * 10000.); }
float noise(vec2 p) { return random(p.x + p.y * 10000.); }

vec2 sw(vec2 p) { return vec2(floor(p.x), floor(p.y)); }
vec2 se(vec2 p) { return vec2(ceil(p.x), floor(p.y)); }
vec2 nw(vec2 p) { return vec2(floor(p.x), ceil(p.y)); }
vec2 ne(vec2 p) { return vec2(ceil(p.x), ceil(p.y)); }

float smoothNoise(vec2 p) {
	vec2 interp = smoothstep(0., 1., fract(p));
	float s = mix(noise(sw(p)), noise(se(p)), interp.x);
	float n = mix(noise(nw(p)), noise(ne(p)), interp.x);
	return mix(s, n, interp.y);
}

float fractalNoise(vec2 p) {
	float n = 0.;
	n += smoothNoise(p);
	n += smoothNoise(p * 2.) / 2.;
	n += smoothNoise(p * 4.) / 4.;
	n += smoothNoise(p * 8.) / 8.;
	n += smoothNoise(p * 16.) / 16.;
	n /= 1. + 1./2. + 1./4. + 1./8. + 1./16.;
	return n;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	vec2 uv = fragCoord.xy / iResolution.xy;
	uv.y = 1.0 - uv.y;
	vec2 nuv = vec2(uv.x - iTime / 6., uv.y);
	vec2 text = fragCoord.xy / iResolution.xy;
	uv *= vec2(1., -1.);


	vec4 baseColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
    
	
	float noiseValue = fractalNoise(nuv * 6.);
	vec3 effectColor = vec3(noiseValue);
    

	effectColor = mix(baseColor.rgb, effectColor, strength);
    
	// Aplicar la transparencia original
	fragColor = vec4(effectColor, baseColor.a);
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}