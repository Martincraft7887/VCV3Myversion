#pragma header

uniform float brightness = 1;
uniform float saturation = 1;
uniform float AAA = 1;
uniform float BBB = 1;

void main() {
    vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
    float f = (color.x+color.y+color.z) / AAA;
    color.xyz = brightness+f*(color.xyz*BBB);

    color.a = flixel_texture2D(bitmap, openfl_TextureCoordv).a;

    gl_FragColor = color;
}