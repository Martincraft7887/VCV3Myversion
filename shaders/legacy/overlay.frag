#pragma header

uniform sampler2D overlayTex;
uniform float posX;
uniform float posY;
uniform float scale;
uniform float angle;
uniform float alpha;

vec2 rotateUV(vec2 uv, float rotation, vec2 center) {
    uv -= center;
    float s = sin(rotation);
    float c = cos(rotation);
    return vec2(
        c * uv.x - s * uv.y,
        s * uv.x + c * uv.y
    ) + center;
}

void main() {
    vec2 uv = openfl_TextureCoordv;
    uv = (uv - vec2(0.5)) / scale;
    uv = rotateUV(uv, angle, vec2(0.0));
    uv += vec2(0.5) + vec2(posX - 0.5, posY - 0.5);

    vec4 sceneColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
    vec4 overlayColor = texture2D(overlayTex, uv);
    overlayColor.a *= alpha;

    gl_FragColor = mix(sceneColor, overlayColor, overlayColor.a);
}