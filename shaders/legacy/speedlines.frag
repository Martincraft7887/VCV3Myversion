// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
uniform float transparency;
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

// The MIT License
// Copyright  2024 Giorgi Azmaipharashvili
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// From David Hoskins (MIT licensed): https://www.shadertoy.com/view/4djSRW
vec3 hash33(vec3 p3) {
	p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx) - 0.5;
}

// From Nikita Miropolskiy (MIT licensed): https://www.shadertoy.com/view/XsX3zB
float simplex3d(vec3 p) {
	 vec3 s = floor(p + dot(p, vec3(1.0 / 3.0)));
	 vec3 x = p - s + dot(s, vec3(1.0 / 6.0));
	 vec3 e = step(vec3(0), x - x.yzx);
	 vec3 i1 = e * (1.0 - e.zxy);
	 vec3 i2 = 1.0 - e.zxy * (1.0 - e);
	 vec3 x1 = x - i1 + 1.0 / 6.0;
	 vec3 x2 = x - i2 + 1.0 / 3.0;
	 vec3 x3 = x - 0.5;
	 vec4 w = max(0.6 - vec4(dot(x, x), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
	 w *= w;
	 return dot(vec4(dot(hash33(s), x), 
                     dot(hash33(s + i1), x1), 
                     dot(hash33(s + i2), x2),  
                     dot(hash33(s + 1.0), x3)) * w * w, vec4(52));
}

void mainImage(out vec4 fragColor, vec2 fragCoord) {
    float time = iTime * 7.0;
    float mr = min(iResolution.x, iResolution.y);
    vec2 uv = (fragCoord.xy * 2.0 - iResolution.xy) / mr * 0.5;
    vec2 p = vec2(0.5) + normalize(uv) * min(length(uv), 0.05);
    vec3 p3 = 13.0 * vec3(p.xy, 0) + vec3(0, 0, time * 0.025);
    float noise = simplex3d(p3 * 32.0) * 0.5 + 0.5;
    float dist = abs(clamp(length(uv) / 12.0, 0.0, 1.0) * noise * 2.0 - 1.0);
    const float e = 0.3;
    float stepped = smoothstep(e - 0.5, e + 0.5, noise * (1.0 - pow(dist, 4.0)));
    float final = smoothstep(e - 0.05, e + 0.05, noise * stepped);
    
    // Asignar el color y el alpha para evitar el fondo negro
	vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

    color.rgb += final * (1.0 - transparency);
    color.rgb = clamp(color.rgb, 0.0, 1.0);

    fragColor = color;
	
}

void main() {
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}

