#pragma header

float blendAdd(float base, float blend) {
	return min(base+blend,1.0);
}

vec3 blendAdd(vec3 base, vec3 blend) {
	return min(base+blend,vec3(1.0));
}

vec3 blendAdd(vec3 base, vec3 blend, float opacity) {
	return (blendAdd(base, blend) * opacity + base * (1.0 - opacity));
}


uniform float iTime;
uniform float strength;

void main()
{
	vec2 uv = openfl_TextureCoordv - vec2(0.5, 0.5);
	vec2 uvStart = uv;
    vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);


	vec4 fractColor = vec4(0.0, 0.0, 0.0, 0.0);

	for (float i = 0.0; i < 5.0; i++) {
		uv = fract(uv * 1.1) - 0.5;

		float d = length(uv) * exp(-length(uvStart));

		d = sin(d*10.0 - iTime*2.0)/20.0;
		d = abs(d);

		d = pow(0.01 / d, 1.7);

		fractColor.rgb += d*0.1;
	}

	color.rgb = blendAdd(color.rgb, fractColor.rgb, strength);
    
	//color = mix(color, fractColor, 0.01);
    
    gl_FragColor = color;
}