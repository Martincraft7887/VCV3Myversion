// fixed by Orsty_Mania

#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
#define texture flixel_texture2D

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

// Dummy variables to avoid crashes
uniform float iTimeDelta;
uniform float iFrameRate;
uniform int iFrame;
#define iChannelTime float[4](iTime, 0., 0., 0.)
#define iChannelResolution vec3[4](iResolution, vec3(0.), vec3(0.), vec3(0.))
uniform vec4 iMouse;
uniform vec4 iDate;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Normalize coordinates (no vertical flipping)
    vec2 uv = fragCoord.xy / iResolution.xy;

    // Background color sampled from the texture
    vec3 backgroundColor = texture(iChannel0, uv).rgb;

    // Frequency visualization parameters
    float fVBars = 50.0;
    float fHSpacing = 1.50;
    float fHFreq = (uv.x * 5.14);
    float squarewave = sign(sin(fHFreq * fVBars) + 1.0 - fHSpacing);

    float x = floor(uv.x * fVBars) / fVBars;
    float fSample = texture(iChannel0, vec2(abs(2.0 * x - 1.0), 0.25)).x;

    float fft = squarewave * fSample * 0.5;

    // Overlay frequencies in white
    vec3 color = mix(backgroundColor, vec3(1.0), step(abs(0.3 - uv.y), fft));

    // Output final color with transparency from the texture
    fragColor = vec4(color, texture(iChannel0, uv).a);
}

void main() {
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}