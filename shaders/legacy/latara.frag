// Fixed by Orsty_Mania

#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
#define texture flixel_texture2D
uniform float iTimeDelta;
uniform float iFrameRate;
uniform int iFrame;
#define iChannelTime float[4](iTime, 0., 0., 0.)
#define iChannelResolution vec3[4](iResolution, vec3(0.), vec3(0.), vec3(0.))
uniform vec4 iMouse;
uniform vec4 iDate;

#define SEQUENCE_LENGTH 74.0
#define FPS 12.0

vec4 vignette(vec2 uv, float time) 
{
    uv *=  1.0 - uv.yx;   
    float vig = uv.x*uv.y * 15.0;
    float t = sin(time * 23.) * cos(time * 8. + .5);
    vig = pow(vig, 0.4 + t * .05);
    return vec4(vig);
}

float easeIn(float t0, float t1, float t) 
{
	return 2.0*smoothstep(t0,2.*t1-t0,t);
}

vec4 blackAndWhite(vec4 color) 
{
    return vec4(dot(color.xyz, vec3(.299, .587, .114)));
}



float filmDirt(vec2 pp, float time) 
{
	float aaRad = 0.1;
	vec2 nseLookup2 = pp + vec2(.5,.9) + time*100.;
	vec3 nse2 =
		textureLod(iChannel0,.1*nseLookup2.xy,0.).xyz +
		textureLod(iChannel0,.01*nseLookup2.xy,0.).xyz +
		textureLod(iChannel0,.004*nseLookup2.xy+0.4,0.).xyz;
	float thresh = .6;
	float mul1 = smoothstep(thresh-aaRad,thresh+aaRad,nse2.x);
	float mul2 = smoothstep(thresh-aaRad,thresh+aaRad,nse2.y);
	float mul3 = smoothstep(thresh-aaRad,thresh+aaRad,nse2.z);
	
	float seed = textureLod(iChannel0,vec2(time*.35,time),0.).x;
	
	float result = clamp(0.,1.,seed+.7) + .3*smoothstep(0.,SEQUENCE_LENGTH,time);
	
	result += .06*easeIn(19.2,19.4,time);

	float band = 0.05;
	if( 0.3 < seed && .3+band > seed )
		return mul1 * result;
	if( 0.6 < seed && .6+band > seed )
		return mul2 * result;
	if( 0.9 < seed && .9+band > seed )
		return mul3 * result;
	return result;
}

vec4 jumpCut(float seqTime) 
{
	float toffset = 0.;
	vec3 camoffset = vec3(0.);
	
	float jct = seqTime;
	float jct1 = 7.7;
	float jct2 = 8.2;
	float jc1 = step( jct1, jct );
	float jc2 = step( jct2, jct );
	
	camoffset += vec3(.8,.0,.0) * jc1;
	camoffset += vec3(-.8,0.,.0) * jc2;
	
	toffset += 0.8 * jc1;
	toffset -= (jc2-jc1)*(jct-jct1);
	toffset -= 0.9 * jc2;
	
	return vec4(camoffset, toffset);
}

float limitFPS(float time, float fps) 
{
    time = mod(time, SEQUENCE_LENGTH);
    return float(int(time * fps)) / fps;
}

vec2 moveImage(vec2 uv, float time) 
{
    uv.x += .002 * (cos(time * 3.) * sin(time * 12. + .25));
    uv.y += .002 * (sin(time * 1. + .5) * cos(time * 15. + .25));
    return uv;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = openfl_TextureCoordv;
    vec2 qq = -1.0 + 2.0 * uv;
    qq.x *= iResolution.x / iResolution.y;
    float time = limitFPS(iTime, FPS);

    vec4 jumpCutData = jumpCut(time);
    vec4 dirt = vec4(filmDirt(qq, time + jumpCutData.w));     
    vec4 image = flixel_texture2D(bitmap, moveImage(uv, time));   
    vec4 vig = vignette(uv, time);
    
    fragColor = image * dirt * vig;
    fragColor = blackAndWhite(fragColor);
}




void main() {
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}