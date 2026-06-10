// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
#define texture flixel_texture2D

// third argument fix
vec4 flixel_texture2D(sampler2D bitmap, vec2 coord, float bias) {
	vec4 color = texture2D(bitmap, coord, bias);
	if (!hasTransform)
	{
		return color;
	}
	if (color.a == 0.0)
	{
		return vec4(0.0, 0.0, 0.0, 0.0);
	}
	if (!hasColorTransform)
	{
		return color * openfl_Alphav;
	}
	color = vec4(color.rgb / color.a, color.a);
	mat4 colorMultiplier = mat4(0);
	colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
	colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
	colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
	colorMultiplier[3][3] = openfl_ColorMultiplierv.w;
	color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);
	if (color.a > 0.0)
	{
		return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}
	return vec4(0.0, 0.0, 0.0, 0.0);
}

// variables which is empty, they need just to avoid crashing shader
uniform float iTimeDelta;
uniform float iFrameRate;
uniform int iFrame;
#define iChannelTime float[4](iTime, 0., 0., 0.)
#define iChannelResolution vec3[4](iResolution, vec3(0.), vec3(0.), vec3(0.))
uniform vec4 iMouse;
uniform vec4 iDate;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 texColor = vec4(0);
    // get position to sample
    vec2 samplePosition = fragCoord.xy / iResolution.xy;
    float whiteNoise = 9999.0;
    
 	// Jitter each line left and right
    samplePosition.x = samplePosition.x+(rand(vec2(iTime,fragCoord.y))-0.5)/64.0;
    // Jitter the whole picture up and down
    samplePosition.y = samplePosition.y+(rand(vec2(iTime))-0.5)/32.0;
    // Slightly add color noise to each line
    texColor = texColor + (vec4(-0.5)+vec4(rand(vec2(fragCoord.y,iTime)),rand(vec2(fragCoord.y,iTime+1.0)),rand(vec2(fragCoord.y,iTime+2.0)),0))*0.1;
   
    // Either sample the texture, or just make the pixel white (to get the staticy-bit at the bottom)
    whiteNoise = rand(vec2(floor(samplePosition.y*80.0),floor(samplePosition.x*50.0))+vec2(iTime,0));
    if (whiteNoise > 11.5-30.0*samplePosition.y || whiteNoise < 1.5-5.0*samplePosition.y) {
        // Sample the texture.
    	samplePosition.y = 1.0-samplePosition.y; //Fix for upside-down texture
    	texColor = texColor + texture(iChannel0,samplePosition);
    } else {
        // Use white. (I'm adding here so the color noise still applies)
        texColor = vec4(1);
    }
	fragColor = texColor;
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}