// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
#define texture flixel_texture2D



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
    vec2 resolution = vec2(640, 360);
    float stepVal = 4.0f;
    float resScale = 0.1f;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    float offset = texture(iChannel1, vec2(iTime*0.1f, 0.0)).g;
    offset = floor(offset * 8.0f) / 8.0f;

    vec3 noiseBase = texture(iChannel1, vec2(uv.y*resScale, offset)).rgb;
    
    float staticNoise = texture(iChannel1, uv*1.3).r;
    
    float noiseR = floor(noiseBase.r*stepVal) / stepVal;
    float noiseG = floor(noiseBase.g*stepVal) / stepVal;
    float noiseB = floor(noiseBase.b*stepVal) / stepVal;
    
    float timeNoise = texture(iChannel1, vec2(iTime*0.1f, 0.0)).r * 0.7f;
    if (timeNoise < 0.4) {
        timeNoise = 0.0f;
    }
    
    //uv = floor(uv * resolution)/ resolution;
    
    // Time varying pixel color
    float r = texture(iChannel0, uv+vec2(noiseR, 0.0)*0.07*timeNoise).r;
    float g = texture(iChannel0, uv+vec2(noiseG, 0.0)*0.07*timeNoise).g;
    float b = texture(iChannel0, uv+vec2(noiseB, 0.0)*0.07*timeNoise).b;
    
    vec3 baseImg = texture(iChannel0, uv).rgb;
    vec3 color = vec3(r,g,b);
    // Output to screen
    fragColor = vec4(color+staticNoise*(timeNoise+0.2)*0.2,texture(iChannel0, uv).a);
    //fragColor = vec4(vec3(timeNoise), texture(iChannel0, uv).a);
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}