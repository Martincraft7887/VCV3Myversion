#pragma header

uniform float strength; // 0 = normal, 1 = invertido total

vec3 getStraightRGB(vec4 color)
{
    return color.a > 0.0 ? color.rgb / color.a : color.rgb;
}

vec4 withAlpha(vec3 rgb, float alpha)
{
    return vec4(clamp(rgb, 0.0, 1.0) * alpha, alpha);
}

void main()
{
    vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv.xy);

    vec3 rgb = getStraightRGB(color);
    vec3 inverted = 1.0 - rgb;

    // Mezcla entre normal e invertido
    rgb = mix(rgb, inverted, strength);

    gl_FragColor = withAlpha(rgb, color.a);
}
