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
	if (!hasTransform)
	{
		return color;
	}
	if (color.a == 0.0)
	{
		return vec4(0.0, 0.0, 0.0, 0.0);
	}
	if (!hasColorTransform)
	{
		return color * openfl_Alphav;
	}
	color = vec4(color.rgb / color.a, color.a);
	mat4 colorMultiplier = mat4(0);
	colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
	colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
	colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
	colorMultiplier[3][3] = openfl_ColorMultiplierv.w;
	color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);
	if (color.a > 0.0)
	{
		return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}
	return vec4(0.0, 0.0, 0.0, 0.0);
}

// variables which is empty, they need just to avoid crashing shader
uniform float iTimeDelta;
uniform float iFrameRate;
uniform int iFrame;
#define iChannelTime float[4](iTime, 0., 0., 0.)
#define iChannelResolution vec3[4](iResolution, vec3(0.), vec3(0.), vec3(0.))
uniform vec4 iMouse;
uniform vec4 iDate;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    bool autoScale = false;
    vec4 channelFactor = vec4(0.9, 1.0, 1.3, 1.0);
    vec4 strength = 0.0 * channelFactor;
    vec4 zoom = (autoScale ? abs(strength) + 1.0 : vec4(1.0));
    
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec2 p = (uv - 0.5) * 2.0; // map [0, 1] to [-1, 1]
    float theta = atan(p.y, p.x);
    float rd = length(p);
    vec4 ru = rd * (1.0 + strength * rd * rd) / zoom;
    vec2 dir = vec2(cos(theta), sin(theta)); 
    vec2 qr = dir * ru.x / 2.0 + 0.5;
    vec2 qg = dir * ru.y / 2.0 + 0.5;
    vec2 qb = dir * ru.z / 2.0 + 0.5;
    vec2 qa = dir * ru.w / 2.0 + 0.5;
    
    fragColor = vec4(
        texture(iChannel0, qr).x,
        texture(iChannel0, qg).y,
        texture(iChannel0, qb).z,
        texture(iChannel0, texture(iChannel0, qr).a);
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}