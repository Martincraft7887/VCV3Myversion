//PlayStationWaves by Orsty_Mania
#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
uniform float strength;
#define iChannel0 bitmap
#define texture flixel_texture2D

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 baseColor = texture(iChannel0, uv);

    vec3 wave_color = vec3(0.0);
    float wave_width = 0.001;

    vec2 uv_waves = -1.0 + 2.0 * uv;
    uv_waves.y += 0.001;

    for(int i = 0; i < 10; i++) {
        float fi = float(i);
        uv_waves.y += (0.057 * sin(uv_waves.x + fi / 7.0 + iTime));
        wave_width = abs(1.0 / (120.0 * uv_waves.y));
        wave_color += vec3(wave_width * 3.5, wave_width, wave_width);
    }

    vec3 final_color = baseColor.rgb + wave_color * strength;
    fragColor = vec4(final_color, baseColor.a);
}

void main() {
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}