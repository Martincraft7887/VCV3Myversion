// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
uniform float strength; // Controls the intensity of the effect
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
#define texture flixel_texture2D
uniform float speed;
// third argument fix
vec4 flixel_texture2D(sampler2D bitmap, vec2 coord, float bias) {
	vec4 color = texture2D(bitmap, coord, bias);
	if (!hasTransform) {
		return color;
	}
	if (color.a == 0.0) {
		return vec4(0.0, 0.0, 0.0, 0.0);
	}
	if (!hasColorTransform) {
		return color * openfl_Alphav;
	}
	color = vec4(color.rgb / color.a, color.a);
	mat4 colorMultiplier = mat4(0);
	colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
	colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
	colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
	colorMultiplier[3][3] = openfl_ColorMultiplierv.w;
	color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);
	if (color.a > 0.0) {
		return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}
	return vec4(0.0, 0.0, 0.0, 0.0);
}

// variables to avoid crashing the shader
uniform float iTimeDelta;
uniform float iFrameRate;
uniform int iFrame;
#define iChannelTime float[4](iTime, 0., 0., 0.)
#define iChannelResolution vec3[4](iResolution, vec3(0.), vec3(0.), vec3(0.))
uniform vec4 iMouse;
uniform vec4 iDate;

#define PI 3.14159265

vec3 tex2D(sampler2D _tex, vec2 _p) {
    vec3 col = texture(_tex, _p).xyz;
    if (0.5 < abs(_p.x - 0.5)) {
        col = vec3(0.1);
    }
    return col;
}

float hash(vec2 _v) {
    return fract(sin(dot(_v, vec2(89.44, 19.36))) * 22189.22);
}

float iHash(vec2 _v, vec2 _r) {
    float h00 = hash(vec2(floor(_v * _r + vec2(0.0, 0.0)) / _r));
    float h10 = hash(vec2(floor(_v * _r + vec2(1.0, 0.0)) / _r));
    float h01 = hash(vec2(floor(_v * _r + vec2(0.0, 1.0)) / _r));
    float h11 = hash(vec2(floor(_v * _r + vec2(1.0, 1.0)) / _r));
    vec2 ip = vec2(smoothstep(vec2(0.0, 0.0), vec2(1.0, 1.0), mod(_v * _r, 1.)));
    return (h00 * (1. - ip.x) + h10 * ip.x) * (1. - ip.y) + (h01 * (1. - ip.x) + h11 * ip.x) * ip.y;
}

float noise(vec2 _v) {
    float sum = 0.;
    for (int i = 1; i < 9; i++) {
        sum += iHash(_v + vec2(i), vec2(2. * pow(2., float(i)))) / pow(2., float(i));
    }
    return sum;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 uvn = uv;
    vec3 col = vec3(0.0);

    // Apply strength to reduce effect intensity
    float effectStrength = strength;

    // Tape wave with strength
    uvn.x += (noise(vec2(uvn.y, iTime)) - 0.5) * 0.005 * effectStrength;
    uvn.x += (noise(vec2(uvn.y * 100.0, iTime * 10.0)) - 0.5) * 0.01 * effectStrength;

    // Tape crease with strength
    float tcPhase = clamp((sin(uvn.y * 8.0 - iTime * PI * speed) - 0.92) * noise(vec2(iTime)), 0.0, 0.01) * 10.0 * effectStrength;
    float tcNoise = max(noise(vec2(uvn.y * 100.0, iTime * 10.0)) - 0.5, 0.0);
    uvn.x = uvn.x - tcNoise * tcPhase;

    // Switching noise with strength
    float snPhase = smoothstep(0.03, 0.0, uvn.y);
    uvn.y += snPhase * 0.3 * effectStrength;
    uvn.x += snPhase * ((noise(vec2(uv.y * 100.0, iTime * 10.0)) - 0.5) * 0.2 * effectStrength);

    col = tex2D(iChannel0, uvn);
    col *= 1.0 - tcPhase;
    col = mix(
        col,
        col.yzx,
        snPhase * effectStrength
    );

    // Bloom effect with strength
    for (float x = -4.0; x < 2.5; x += 1.0) {
        col.xyz += vec3(
            tex2D(iChannel0, uvn + vec2(x - 0.0, 0.0) * 7E-3 * effectStrength).x,
            tex2D(iChannel0, uvn + vec2(x - 2.0, 0.0) * 7E-3 * effectStrength).y,
            tex2D(iChannel0, uvn + vec2(x - 4.0, 0.0) * 7E-3 * effectStrength).z
        ) * 0.1;
    }
    col *= 0.6;

    // AC beat with strength
    col *= 1.0 + clamp(noise(vec2(0.0, uv.y + iTime * 0.2)) * 0.6 - 0.25, 0.0, 0.1 * effectStrength);

    fragColor = vec4(col, texture(iChannel0, uv).a);
}

void main() {
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}