//SHADERTOY PORT FIX
#pragma header
vec2 uv = openfl_TextureCoordv.xy;
vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
vec2 iResolution = openfl_TextureSize;
uniform float iTime;
#define iChannel0 bitmap
#define texture flixel_texture2D
#define fragColor gl_FragColor
#define mainImage main
#define time iTime
//SHADERTOY PORT FIX

void mainImage()
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec4 color = texture(iChannel0, uv);
    
    float strength = 25.0;
    
    float x = (uv.x + 4.0 ) * (uv.y + 4.0 ) * (iTime * 10.0);
	vec4 grain = vec4(mod((mod(x, 13.0) + 1.0) * (mod(x, 123.0) + 1.0), 0.01)-0.005) * strength;
    
    if(abs(uv.x - 0.9999) < 0.002)
        color = vec4(0.0);
    
    if(uv.x > 0.9999)
    {
    	grain = 1.0 - grain;
		fragColor = color * grain;
    }
    else
    {
		fragColor = color + grain;
    }
}