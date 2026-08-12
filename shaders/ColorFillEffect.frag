#pragma header

uniform float red;
uniform float green;
uniform float blue;
uniform float alpha;

void main()
{
	vec4 spriteColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
	float intensity = clamp(alpha, 0.0, 1.0);

	vec3 fillColor = vec3(red, green, blue) / 255.0 * spriteColor.a;
	vec3 finalColor = mix(spriteColor.rgb, fillColor, intensity);

	gl_FragColor = vec4(finalColor, spriteColor.a);
}
