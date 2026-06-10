#pragma header

vec2 uv = openfl_TextureCoordv.xy;
vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
vec2 iResolution = openfl_TextureSize;
uniform float iTime;
#define iChannel0 bitmap
#define texture flixel_texture2D
#define fragColor gl_FragColor

float Threshold = 0.45; // Default is 0.05
float Intensity = 1.5; // Default is 1.0

vec4 blend(in vec2 Coord, in sampler2D Tex, in float MipBias)
{
	vec2 TexelSize = MipBias/iResolution.xy;

	vec4 Color = texture(Tex, Coord);
    
    // Take 6 samples from the texture
	Color += texture(Tex, Coord + vec2(TexelSize.x,TexelSize.y));
	Color += texture(Tex, Coord + vec2(TexelSize.x/2.0,TexelSize.y/2.0));
	Color += texture(Tex, Coord + vec2(TexelSize.x/3.0,TexelSize.y/3.0));
	Color += texture(Tex, Coord + vec2(TexelSize.x/4.0,TexelSize.y/4.0));
	Color += texture(Tex, Coord + vec2(TexelSize.x/5.0,TexelSize.y/5.0));
	Color += texture(Tex, Coord + vec2(TexelSize.x/6.0,TexelSize.y/6.0));
	Color += texture(Tex, Coord + vec2(-TexelSize.x,TexelSize.y));
	Color += texture(Tex, Coord + vec2(-TexelSize.x/2.0,TexelSize.y/2.0));
	Color += texture(Tex, Coord + vec2(-TexelSize.x/3.0,TexelSize.y/3.0));
	Color += texture(Tex, Coord + vec2(-TexelSize.x/4.0,TexelSize.y/4.0));
	Color += texture(Tex, Coord + vec2(-TexelSize.x/5.0,TexelSize.y/5.0));
	Color += texture(Tex, Coord + vec2(-TexelSize.x/6.0,TexelSize.y/6.0));
	Color += texture(Tex, Coord + vec2(TexelSize.x,-TexelSize.y));
	Color += texture(Tex, Coord + vec2(TexelSize.x/2.0,-TexelSize.y/2.0));
	Color += texture(Tex, Coord + vec2(TexelSize.x/3.0,-TexelSize.y/3.0));
	Color += texture(Tex, Coord + vec2(TexelSize.x/4.0,-TexelSize.y/4.0));
	Color += texture(Tex, Coord + vec2(TexelSize.x/5.0,-TexelSize.y/5.0));
	Color += texture(Tex, Coord + vec2(-TexelSize.x/6.0,-TexelSize.y/6.0));
	Color += texture(Tex, Coord + vec2(-TexelSize.x,-TexelSize.y));
	Color += texture(Tex, Coord + vec2(-TexelSize.x/2.0,-TexelSize.y/2.0));
	Color += texture(Tex, Coord + vec2(-TexelSize.x/3.0,-TexelSize.y/3.0));
	Color += texture(Tex, Coord + vec2(-TexelSize.x/4.0,-TexelSize.y/4.0));
	Color += texture(Tex, Coord + vec2(-TexelSize.x/5.0,-TexelSize.y/5.0));
	Color += texture(Tex, Coord + vec2(TexelSize.x/6.0,-TexelSize.y/6.0));

	return Color/24.0;
}

void main()
{
	vec2 uv = (fragCoord.xy/iResolution.xy)*vec2(1.0,1.0);

	vec4 Color = texture(iChannel0, uv);

	vec4 Highlight = clamp(blend(uv, iChannel0, 4.0)-Threshold,0.0,1.0)*1.0/(1.0-Threshold);

	fragColor = 1.0-(1.0-Color)*(1.0-Highlight*Intensity);
}