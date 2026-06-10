#pragma header

uniform float uTime;
uniform float uWindowWidth;
uniform float uWindowHeight;

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec2 center = vec2(0.5, 0.5);
    float distanceToCenter = length(uv - center);
    float squeeze = sin(uTime * 2.0) * 0.1;
    uv = center + (uv - center) * (1.0 - squeeze * distanceToCenter);
    vec2 windowUV = uv * openfl_TextureSize.xy / vec2(uWindowWidth, uWindowHeight);
    float isOutside = step(0.99, max(abs(windowUV.x - 0.5), abs(windowUV.y - 0.5)));
    vec4 color = flixel_texture2D(bitmap, uv);
    color.rgb *= 1.0 - isOutside * 0.8;
    gl_FragColor = color;
}