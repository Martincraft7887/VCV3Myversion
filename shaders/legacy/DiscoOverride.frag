#pragma header

uniform float iTime;
uniform float brightness;
uniform float enableRainbow;

void main()
{
    vec4 spritecolor = flixel_texture2D(bitmap, openfl_TextureCoordv);

    float speed = 10.0;
    float red = mix(1.0, sin(iTime * speed) * 0.5 + 0.5, enableRainbow);
    float green = mix(1.0, sin(iTime * speed + 2.094) * 0.5 + 0.5, enableRainbow);
    float blue = mix(1.0, sin(iTime * speed + 4.188) * 0.5 + 0.5, enableRainbow);

    spritecolor.r *= red * brightness;
    spritecolor.g *= green * brightness;
    spritecolor.b *= blue * brightness;

    gl_FragColor = spritecolor;
}