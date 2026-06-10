#pragma header

uniform float strength;
uniform float paletteSize;

vec3 getStraightRGB(vec4 color)
{
	return color.a > 0.0 ? color.rgb / color.a : color.rgb;
}

vec4 withAlpha(vec3 rgb, float alpha)
{
	return vec4(clamp(rgb, 0.0, 1.0) * alpha, alpha);
}

float palette(float val, float size)
{
	float f = floor(val * (size-1.0) + 0.5);
	return f / (size-1.0);
}
void main()
{
	vec2 uv = openfl_TextureCoordv;
	vec4 col = flixel_texture2D(bitmap, uv);
	
	vec3 rgb = getStraightRGB(col);
	vec4 reducedCol = vec4(rgb.r,rgb.g,rgb.b,col.a);

	reducedCol.r = palette(reducedCol.r, 8.0);
	reducedCol.g = palette(reducedCol.g, 8.0);
	reducedCol.b = palette(reducedCol.b, 8.0);
	gl_FragColor = withAlpha(mix(rgb, reducedCol.rgb, strength), col.a);
}
