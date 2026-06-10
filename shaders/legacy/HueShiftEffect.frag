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

vec3 hueShift(vec3 c,float shift){
    float Max = max(max(c.x,c.y),c.z);
    float Min = min(min(c.x,c.y),c.z);
    float chr = Max-Min;
    float hue = 0.;
    if(Max == c.x){
        hue = (c.y-c.z)/chr;
    }else if(Max == c.y){
        hue = 2.+(c.z-c.x)/chr;
    }else{
        hue = 4.+(c.x-c.y)/chr;}
    float sat = chr/Max;
    float val = Max;
    hue += shift;
    hue = mod(hue,6.);
    
    float x = chr*(1.-abs(mod(hue,2.)-1.));
    vec3 rgb = vec3(0.);
    if(hue>=0.,hue<=1.){
        rgb = vec3(chr,x,0.);}
    else if(hue>1.,hue<=2.){
        rgb = vec3(x,chr,0.);}
    else if(hue>2.,hue<=3.){
        rgb = vec3(0.,chr,x);}
    else if(hue>3.,hue<=4.){
        rgb = vec3(0.,x,chr);}
    else if(hue>4.,hue<=5.){
        rgb = vec3(x,0.,chr);}
    else{
        rgb = vec3(chr,0.,x);};
    return rgb+val-chr;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec3 c = texture(iChannel0,uv).xyz;
    
    fragColor = vec4(hueShift(c,iTime),texture(iChannel0, uv).a);
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}