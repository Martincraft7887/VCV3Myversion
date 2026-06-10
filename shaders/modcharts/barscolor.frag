#pragma header

uniform float effect;
uniform float effect2;
uniform float angle1;
uniform float angle2;

uniform float color1R;
uniform float color1G;
uniform float color1B;
uniform float color1A;

uniform float color2R;
uniform float color2G;
uniform float color2B;
uniform float color2A;

vec2 rotate(vec2 p, float a, vec2 center)
{
    p -= center;
    float cosA = cos(a);
    float sinA = sin(a);
    p = vec2(
        cosA * p.x - sinA * p.y,
        sinA * p.x + cosA * p.y
    );
    return p + center;
}

void main()
{
    vec2 uv = openfl_TextureCoordv.xy;
    vec4 Color = flixel_texture2D(bitmap, uv);

    vec2 uv1 = rotate(uv, angle1, vec2(0.5));
    vec2 uv2 = rotate(uv, angle2, vec2(0.5));

    if (uv1.y < effect || uv1.y > 1.0 - effect) {
        Color = vec4(color1R, color1G, color1B, color1A);
    }

    if (uv2.x < effect2 || uv2.x > 1.0 - effect2) {
        Color = vec4(color2R, color2G, color2B, color2A);
    }

    gl_FragColor = Color;
}