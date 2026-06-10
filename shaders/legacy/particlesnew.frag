// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform float transparency;
uniform float red;
uniform float green;
uniform float blue;
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

float random (float x) {
    return fract(sin(x)*1e4);
}

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

float sdSegment(vec2 st, vec2 a, vec2 b )
{
    vec2 pa = st-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 0.1 );
    return length( pa - ba*h );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 st = (fragCoord.xy * 1.2 - iResolution.xy) / iResolution.y; 
    
    vec3 col = vec3(0.);    
    float coef = 3.0;
    vec2 st0 = st;
    st *= coef;    
    st.y += iTime * coef;
    st.x += sin(iTime * 2.0 * random(0.1));

    vec2 i_st = floor(st);
    vec2 f_st = fract(st);    
   
    float m_dist = 1.;

    for (int y= -1; y <= 1; y++) {
        for (int x= -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x) ,float(y));  
            vec2 point = random2(i_st + neighbor);            
            float sinTiming = 0.5 + 0.5*sin(iTime * 5. + 6.2831);
            float cosTiming = 0.5 + 0.5*cos(iTime * 5. + 6.2831);
            point = 0.4 + 0.4*sin(iTime * 3. + 10.2831*point);

            vec2 diff = neighbor + point - f_st;
            float dist = sdSegment(diff, vec2(0.01), vec2(sinTiming * abs((0.5-point.x)), cosTiming * 0.2));
            m_dist = min(m_dist, dist);
        }
    }
    
    m_dist = 0.02 / m_dist;
    m_dist = abs(m_dist); 
    col += m_dist;
    st0 *= 0.2;   
    st0 = cos(st0);
    col *= vec3(1.5 * cos(st0.y), 0.3, 0.6) * st0.x;       
    
    vec4 baseColor = flixel_texture2D(bitmap, openfl_TextureCoordv);

    vec4 colorAdjustment = vec4(red/1.0, green/1.0, blue/1.0, baseColor.a);

    col *= colorAdjustment.rgb;
    
    // Mezclar el alpha con transparencia
    float alpha = baseColor.a * (1.0 - transparency);
    baseColor.rgb += col * alpha;

    fragColor = vec4(baseColor.rgb, alpha); // Aplicar color y alpha resultante
}


void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}