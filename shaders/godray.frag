#pragma header

uniform float iTime;
uniform float decay;
uniform float density;
uniform float weight;
uniform float exposure;

void main()
{
    vec2 uv = openfl_TextureCoordv;

    vec4 base = flixel_texture2D(bitmap, uv);

    vec2 lightPos = vec2(
        0.5 + sin(iTime * 0.7) * 0.25,
        0.5 + cos(iTime * 0.9) * 0.25
    );

    vec2 delta = (uv - lightPos) * density / 240.0;
    vec2 coord = uv;

    float illum = 1.0;
    vec4 col = vec4(0.0);

    for (int i = 0; i < 30; i++)
    {
        coord -= delta;

        vec4 samp = flixel_texture2D(bitmap, coord);
        samp *= illum;

        col += samp;

        illum *= decay;
    }

    col /= 30.0;

    vec4 finalColor = base + col * weight;

    finalColor.rgb *= exposure;

    gl_FragColor = finalColor;
}