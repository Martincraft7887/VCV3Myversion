#pragma header

uniform float red;
uniform float green;
uniform float blue;

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
	vec4 spritecolor = flixel_texture2D(bitmap, openfl_TextureCoordv);
	vec3 rgb = getStraightRGB(spritecolor);

	rgb.r *= red;
	rgb.g *= green;
	rgb.b *= blue;

	gl_FragColor = withAlpha(rgb, spritecolor.a);
}
