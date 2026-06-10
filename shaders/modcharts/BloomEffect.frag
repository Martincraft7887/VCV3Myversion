#pragma header

uniform float effect;
uniform float strength;

uniform float contrast;
uniform float brightness;

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
	vec2 iResolution = vec2(1280.0, 720.0);


	vec4 color = flixel_texture2D(bitmap,uv);
	vec3 rgb = getStraightRGB(color);
	//float brightness = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));

	//vec4 newColor = vec4(color.rgb * brightness * strength * color.a, color.a);

	//got some stuff from here: https://github.com/amilajack/gaussian-blur/blob/master/src/9.glsl
	//this also helped to understand: https://learnopengl.com/Advanced-Lighting/Bloom


	rgb *= contrast;
	rgb += vec3(brightness,brightness,brightness);
	color = withAlpha(rgb, color.a);

	if (effect <= 0.0)
	{
		gl_FragColor = color;
		return;
	}


	vec2 off1 = vec2(1.3846153846) * effect;
	vec2 off2 = vec2(3.2307692308) * effect;

	color += flixel_texture2D(bitmap, uv) * 0.2270270270 * strength;
	color += flixel_texture2D(bitmap, uv + (off1 / iResolution)) * 0.3162162162 * strength;
	color += flixel_texture2D(bitmap, uv - (off1 / iResolution)) * 0.3162162162 * strength;
	color += flixel_texture2D(bitmap, uv + (off2 / iResolution)) * 0.0702702703 * strength;
	color += flixel_texture2D(bitmap, uv - (off2 / iResolution)) * 0.0702702703 * strength;

	gl_FragColor = color;
}
