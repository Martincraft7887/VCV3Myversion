#pragma header

uniform bool visible;

uniform vec3 red;
uniform vec3 green;
uniform vec3 blue;

void main() {
    vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
    gl_FragColor = visible ? vec4(color.r * red + color.g * green + color.b * blue, color.a) : color;
}
