#pragma header

uniform float iTime;
uniform float strength;
uniform float speed;

float random(float n)
{
    return fract(sin(n) * 43758.5453123);
}

vec2 spiral(vec2 uv)
{
    vec2 finalUV = uv;

    float t = iTime * speed;

    // cantidad de espirales
    for (int i = 0; i < 5; i++)
    {
        float fi = float(i);

        // posiciones pseudoaleatorias
        vec2 center = vec2(
            random(fi * 12.34),
            random(fi * 56.78)
        );

        // mover con el tiempo para que cambien
        center += vec2(
            sin(t * 0.3 + fi) * 0.1,
            cos(t * 0.2 + fi) * 0.1
        );

        vec2 p = finalUV - center;

        float dist = length(p);
        float angle = atan(p.y, p.x);

        // fuerza dependiendo de cercania
        float influence = exp(-dist * 8.0);

        // espiral
        float spiralWave =
            sin((dist * 40.0) - (angle * 5.0) + t);

        angle += spiralWave * 0.25 * strength * influence;

        vec2 warped;
        warped.x = cos(angle) * dist;
        warped.y = sin(angle) * dist;

        finalUV = center + warped;
    }

    return finalUV;
}

void main()
{
    vec2 uv = openfl_TextureCoordv.xy;

    vec2 distortedUV = spiral(uv);

    vec4 col = flixel_texture2D(bitmap, distortedUV);

    gl_FragColor = col;
}