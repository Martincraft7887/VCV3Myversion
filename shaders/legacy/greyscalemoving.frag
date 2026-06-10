#pragma header

uniform float strength;
uniform vec2 iResolution;

const float Soft = 0.1;
const float Threshold = 0.3;

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec4 col = flixel_texture2D(bitmap, uv);

    float f = Soft / 2.0;
    float a = Threshold - f;
    float b = Threshold + f;

    float l = (col.x + col.y + col.z) / 3.0;
    float v = smoothstep(a, b, l);

    vec4 grayscaleEffect = vec4(vec3(v), col.a);
    gl_FragColor = mix(col, grayscaleEffect, strength);
}
