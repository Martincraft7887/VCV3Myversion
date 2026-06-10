#pragma header

uniform float iTime;
uniform float strength;
uniform float speed;

vec2 water(vec2 uv)
{
    float t = iTime * speed;

    // ondas suaves tipo agua
    float waveX = sin((uv.y * 10.0) + t) * 0.01;
    float waveY = cos((uv.x * 10.0) + t) * 0.01;

    return uv + vec2(waveX, waveY) * strength;
}

void main()
{
    vec2 uv = openfl_TextureCoordv.xy;

    vec2 distortedUV = water(uv);

    vec4 col = flixel_texture2D(bitmap, distortedUV);

    gl_FragColor = col;
}