#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
uniform float strength;
uniform float strengthGlow;
uniform float strengthDark;
uniform float flashX;
uniform float flashY;
uniform float sizeX;
uniform float sizeY;

#define iChannel0 bitmap
#define texture flixel_texture2D

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
    vec4 texColor = texture(iChannel0, fragCoord / iResolution.xy);

    float flashWidth = sizeX;
    float flashHeight = sizeY;

    float flashIntensity = strengthGlow;

    vec2 flashCenter = vec2(0.5 + flashX, 0.5 + flashY);
    vec2 dist = (uv - flashCenter) / vec2(flashWidth, flashHeight);
    float lightMask = smoothstep(1.0, 0.9, length(dist));

    float insideMask = smoothstep(1.10, 0.75, length(dist)); 

    vec3 darkColor = texColor.rgb * mix(0.02, 0.5, strength) * insideMask;
    
    vec3 flashColor = texColor.rgb * flashIntensity;

    
    vec3 globalDarkColor = texColor.rgb * mix(1.0, strengthDark, 1.0 - lightMask);

    float contourEffect = smoothstep(0.95, 0.85, length(dist));

    fragColor = vec4(mix(darkColor, flashColor, lightMask + contourEffect) + globalDarkColor, texColor.a);
}

void main() {
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}