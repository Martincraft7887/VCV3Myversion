// shader for ONLY spritesheets

#pragma header

uniform vec3 fillColor;
uniform float fillStrength;
uniform float outlineStrength;
uniform float iTime;
uniform vec4 frameBounds; 

void main()
{
    vec2 uv = openfl_TextureCoordv;
    vec4 src = flixel_texture2D(bitmap, uv);

    if (src.a <= 0.0) {
        gl_FragColor = vec4(0.0);
        return;
    }

    vec4 bounds = frameBounds;
    if (bounds.z <= bounds.x || bounds.w <= bounds.y) {
        bounds = vec4(0.0, 0.0, 1.0, 1.0);
    }
    vec2 frameCenter = (bounds.xy + bounds.zw) * 0.5;
    vec2 frameSize = bounds.zw - bounds.xy;
    
    vec2 relPos = (uv - frameCenter) / frameSize;

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