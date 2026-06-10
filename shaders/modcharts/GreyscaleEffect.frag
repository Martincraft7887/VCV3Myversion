#pragma header
		
uniform float strength;

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
	vec2 uv = openfl_TextureCoordv;
	vec4 col = flixel_texture2D(bitmap, uv);
	vec3 rgb = getStraightRGB(col);
	float grey = dot(rgb, vec3(0.299, 0.587, 0.114)); //https://en.wikipedia.org/wiki/Grayscale
	gl_FragColor = withAlpha(mix(rgb, vec3(grey, grey, grey), strength), col.a);
}
