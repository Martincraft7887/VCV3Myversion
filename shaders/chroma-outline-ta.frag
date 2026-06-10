// shader for ONLY texture atlases

#pragma header

uniform vec3 fillColor;
uniform float fillStrength;
uniform float outlineStrength;
uniform float iTime;

void main()
{
    vec2 uv = openfl_TextureCoordv;
    vec4 src = flixel_texture2D(bitmap, uv);

    if (src.a <= 0.0) {
        gl_FragColor = vec4(0.0);
        return;
    }

    vec2 relPos = uv - vec2(0.5, 0.5);

    float angle = atan(relPos.y, relPos.x);
    float brightness = (src.r + src.g + src.b) / 3.0;
    float isOutline = 1.0 - smoothstep(0.0, 0.3, brightness);
    float hue = angle + (iTime * 3.0);

    vec3 chroma = 0.5 + 0.5 * cos(hue + vec3(0, 2, 4));
    vec3 bodyResult = mix(src.rgb, fillColor, fillStrength);
    vec3 outlineResult = mix(src.rgb, chroma, outlineStrength);
    vec3 finalRGB = mix(bodyResult, outlineResult, isOutline);

    gl_FragColor = vec4(finalRGB * src.a, src.a);
}