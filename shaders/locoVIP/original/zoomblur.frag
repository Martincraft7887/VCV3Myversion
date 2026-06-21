// Source: https://www.shadertoy.com/view/XsfSDs
// little rewritted and ported to flixel by TheLeerName

#pragma header

uniform float posX; // from 0.0 to 1.0
uniform float posY; // from 0.0 to 1.0
uniform float focusPower; // 10.0

#define focusDetail 7.0
void main() {
    vec2 uv = openfl_TextureCoordv;
    vec2 pos = vec2(posX, posY);
	vec2 focus = uv - pos;

    vec4 outColor = vec4(0.0);

    for (int i=0; i< int(focusDetail); i++) {
        float power = 1.0 - focusPower * (1.0/openfl_TextureSize.x) * float(i);
        outColor += flixel_texture2D(bitmap, focus * power + pos);
    }

    outColor *= 1.0 / focusDetail;

	gl_FragColor = outColor;
}