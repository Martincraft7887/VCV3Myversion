#pragma header

uniform float effect;    
uniform float effect2;   
uniform float angle1;
uniform float angle2;
uniform float color;
uniform float barsStyle;

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

    vec2 distortedUV = uv;

    float rad1 = -angle1 * 3.14159265 / 180.0;
    float rad2 = -angle2 * 3.14159265 / 180.0;

    vec2 rotatedUV1 = rotate(distortedUV, rad1, vec2(0.5));
    vec2 rotatedUV2 = rotate(distortedUV, rad2, vec2(0.5));

    if (barsStyle < 0.001)
    {
        if (
            rotatedUV1.y < effect || rotatedUV1.y > 1.0 - effect || 
            rotatedUV2.x < effect2 || rotatedUV2.x > 1.0 - effect2
        )
        {
            vec3 bw = mix(vec3(0.0), vec3(1.0), clamp(color, 0.0, 1.0));
            Color = vec4(bw, 1.0);
        }
    }
    else
    {
        float barSpacing = 0.015; // for change space of bar
        float barWidth = 0.015; // for change size bar
        float startFalloff = 0.3; // for change start fade bar
        float bw = clamp(color, 0.0, 1.0);
        float spacing = max(barSpacing, 0.001);
        float width = clamp(barWidth, 0.0, spacing);

        if (rotatedUV1.y < effect || rotatedUV1.y > 1.0 - effect)
        {
            float distEdge = min(rotatedUV1.y, 1.0 - rotatedUV1.y) / effect;
            float factor = clamp((distEdge - startFalloff) / (1.0 - startFalloff), 0.0, 1.0);
            float adjustedWidth = width * (1.0 - factor);
            float stripe = fract(rotatedUV1.y / spacing);
            if (stripe < adjustedWidth / spacing)
            {
                Color = vec4(vec3(bw), 1.0);
            }
        }

        if (rotatedUV2.x < effect2 || rotatedUV2.x > 1.0 - effect2)
        {
            float distEdge = min(rotatedUV2.x, 1.0 - rotatedUV2.x) / effect2;
            float factor = clamp((distEdge - startFalloff) / (1.0 - startFalloff), 0.0, 1.0);
            float adjustedWidth = width * (1.0 - factor);
            float stripe = fract(rotatedUV2.x / spacing);
            if (stripe < adjustedWidth / spacing)
            {
                Color = vec4(vec3(bw), 1.0);
            }
        }
    }

    gl_FragColor = Color;
}