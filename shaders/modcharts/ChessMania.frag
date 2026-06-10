#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)

uniform float iTime;
uniform float transparency;
uniform float direction; 
uniform float directionY; 
uniform float chessSize;
uniform float fisheyeStrength;
uniform float borderWidthX;
uniform float borderWidthY;
uniform float chessGlow; 

#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
#define texture flixel_texture2D

vec2 eyefishDistortion(vec2 coord, vec2 resolution, float strength) {
    vec2 center = resolution * 0.5;
    vec2 offset = coord - center;
    float r = length(offset);
    if (r == 0.0) return coord;
    float theta = atan(offset.y, offset.x);
    float rn = pow(r / length(center), 1.0 - strength * 0.75) * length(center);
    return center + vec2(cos(theta), sin(theta)) * rn;
}

float borderFactor(vec2 coord, vec2 resolution, float widthX, float widthY) {
    float left = smoothstep(widthX, 0.0, coord.x);
    float right = smoothstep(widthX, 0.0, resolution.x - coord.x);
    float top = smoothstep(widthY, 0.0, coord.y);
    float bottom = smoothstep(widthY, 0.0, resolution.y - coord.y);
    return max(max(left, right), max(top, bottom));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float b = borderFactor(fragCoord, iResolution.xy, borderWidthX, borderWidthY);
    float effectStrength = b * fisheyeStrength;
    vec2 distortedCoord = mix(fragCoord, eyefishDistortion(fragCoord, iResolution.xy, 1.0), effectStrength);

    float cx = distortedCoord.x * chessSize * 0.1 + direction * 5.0 * iTime;
    float cy = distortedCoord.y * chessSize * 0.1 + directionY * 5.0 * iTime;

    float checker = mod(floor(cx) + floor(cy), 2.0);

    vec2 uv = fragCoord / iResolution.xy;
    vec4 baseColor = texture(iChannel0, uv);

    vec3 glowColor = vec3(1.0) * chessGlow;
    vec3 checkerColor = mix(baseColor.rgb, glowColor, checker * transparency);

    fragColor = vec4(checkerColor, baseColor.a);
}

void main() {
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}