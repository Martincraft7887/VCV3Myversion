#pragma header

#define PI 3.14159265359
uniform float num_samples;
uniform float hh;
uniform float kstep;
uniform float ksum;
uniform float eatt;
uniform float iTime;
vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
vec2 iResolution = openfl_TextureSize;


vec3 attenuation(vec3 c, float d)
{
    return c/exp(eatt*d);
}


vec3 radial_blur_filter(in vec2 origin, in vec2 point)
{
    vec4 fon = texture2D(bitmap, point);
    vec3 col = fon.rgb * fon.a;
    vec3 light = vec3(0.0);
    vec2 v = point - origin;
    float l = length(v);
    v = normalize(v); 
    float dz =  hh / num_samples * ksum;
    float l1 = l/(1.0 + hh);
    float al = (l-l1);
    for(float s = 0.0; s < num_samples; s++)
    {
        float l2 = l1 + al*s/num_samples;
        vec2 p = origin + v*l2;
        
        vec3 c = texture2D(bitmap, p).rgb;
        float pst = smoothstep(kstep, 0.5, c.g);
        c *= pst;

        float fi = atan(l2, 1.0);
        float d = (l - l2)/sin(fi);
        c = attenuation(c, d);
        light += c;
    }
    light *= dz;
    float pst = smoothstep(0.0, 1.0, col.g);  
	light*=(1.0 - pst);
    
    col += light;
    return col;
}

void main()
{
    vec2 pt = fragCoord.xy/iResolution.xy;
    vec4 col = texture2D(bitmap, pt);
    vec2 mouse = vec2(0.5+0.1*sin(iTime*2.),0.25+0.1*cos(iTime*1.25));
    col.rgb = radial_blur_filter(mouse, pt);
    gl_FragColor = col;
    
}