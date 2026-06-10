#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
uniform float speed;
uniform float strength;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
#define texture flixel_texture2D

#define invert_color

float rand(float x) {
    return fract(sin(x) * 43758.5453);
}

float triangle(float x) {
    return abs(1.0 - mod(abs(x), 2.0)) * 2.0 - 1.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

	
    float time = floor(iTime*speed) / 16.0;
        vec2 uv = fragCoord.xy / iResolution.xy;
    
    // pixel position
	vec2 p = uv;	
	p += vec2(triangle(p.y * rand(time + strength) * 4.0) * rand(strength + time * 1.9) * 0.015,
			triangle(p.x * rand(time + strength * 3.4) * 4.0) * rand(time + strength* 2.1) * 0.015);
	p += vec2(rand(p.x * 3.1 + p.y * 8.7) * 0.01,
			  rand(p.x * 1.1 + p.y * 6.7) * 0.01);
    	    

    #ifdef distort_all
    vec2 blurredUV = vec2(p.x + 0.003, p.y + 0.003);
    vec4 baseColor = vec4(texture(iChannel0, blurredUV).rgb, 1.0);
    #else
    vec4 baseColor = vec4(texture(iChannel0, uv).rgb, 1.0);
    #endif

    vec4 edges = 1.0 - (baseColor / vec4(texture(iChannel0, p).rgb, 1.5));

    #ifdef invert_color
    baseColor.rgb = vec3(baseColor.r);
    fragColor = baseColor / vec4(length(edges));
    #else
    fragColor = mix(baseColor, vec4(length(edges)), strength);
    #endif
}

void main() {
    vec4 fragColor;
    mainImage(fragColor, openfl_TextureCoordv * openfl_TextureSize);

    if (strength <= 0.0) {
        gl_FragColor = texture(iChannel0, openfl_TextureCoordv.xy);
    } else {
        gl_FragColor = fragColor;
    }
}