#pragma header

uniform float temperature;
uniform float saturation;
uniform float contrast;

vec3 getStraightRGB(vec4 color)
{
    return color.a > 0.0 ? color.rgb / color.a : color.rgb;
}

vec4 withAlpha(vec3 rgb, float alpha)
{
    return vec4(clamp(rgb, 0.0, 1.0) * alpha, alpha);
}

vec3 adjustTemperature(vec3 color, float temp)
{
    // Multiplicadores tipo RGB
    float rMul = 1.0 + (temp * 0.1);
    float bMul = 1.0 - (temp * 0.1);

    color.r *= rMul;
    color.b *= bMul;

    return clamp(color, 0.0, 1.0);
}

vec3 adjustSaturation(vec3 color, float sat)
{
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), color, sat);
}

vec3 adjustContrast(vec3 color, float con)
{
    return (color - 0.5) * con + 0.5;
}

void main()
{
    vec4 tex = flixel_texture2D(bitmap, openfl_TextureCoordv);

    vec3 col = getStraightRGB(tex);

    col = adjustTemperature(col, temperature);
    col = adjustSaturation(col, saturation);
    col = adjustContrast(col, contrast);

    gl_FragColor = withAlpha(col, tex.a);
}
