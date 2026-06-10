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

const float EExposure   = 0.1;                      /* F-Stops */
const float EMidGray    = 0.5;
const float EContrast   = 1.2;
const float ESaturation = 1.0;
const float EVibrance   = 0.3;
const int   ETemp       = 6100;                     /* COLOR TEMPERATURE IN DEGREES KELVIN, 6600 = WHITE */
const vec3  ETint       = vec3(0.9, 0.95, 0.9);     /* sRGB COLOR NORMALIZED TO 0-1 RANGE */
const float EDesat      = 1.0;                      /* FACTOR OF HIGHLIGHT DESATURATION */
const float ECurve      = 0.2;                      /* TONEMAPPER CURVE */
const float EShift      = 0.0;                      /* FACTOR OF HUE SHIFT DURING TONEMAPPING */

/* LUMINANCE WEIGHTS */
#define L709  vec3(0.2126, 0.7152, 0.0722)
#define L2020 vec3(0.2627, 0.678,  0.0593)

/* PRECOMPUTED LOGC4 PARAMETERS */
#define LOGC_A    2231.8263090676883
#define LOGC_B    0.9071358748778103
#define LOGC_C    0.09286412512218964
#define LOGC_S    0.1135972086105891
#define LOGC_T    -0.01805699611991131

/* PRECOMPUTED PQ PARAMETERS */
#define PQ_C1   0.8359375
#define PQ_C2   18.8515625
#define PQ_C3   18.6875
#define PQ_M1   0.159301758125
#define PQ_M2   78.84375
#define PQ_MAX  100.00


/* R709 <-> R2020 MATRICES */
/* https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.2087-0-201510-I!!PDF-E.pdf */
const mat3 m_r709_r2020 = mat3(
    +0.6274,    +0.3293,    +0.0433,
    +0.0691,    +0.9195,    +0.0114,
    +0.0164,    +0.0880,    +0.8956);
/* https://www.itu.int/dms_pub/itu-r/opb/rep/R-REP-BT.2407-2017-PDF-E.pdf */
const mat3 m_r2020_r709 = mat3(
    +1.6605,    -0.5876,    -0.0728,
    -0.1246,    +1.1329,    -0.0083,
    -0.0182,    -0.1006,    +1.1187);

/* R2020 <-> LMS MATRICES */
/* https://professional.dolby.com/siteassets/pdfs/ictcp_dolbywhitepaper_v071.pdf */
const mat3 m_r2020_lms = mat3(
    +0.412109375,               +0.52392578125,            +0.06396484375,
    +0.166748046875,            +0.720458984375,           +0.11279296875,
    +0.024169921875,            +0.075439453125,           +0.900390625);
const mat3 m_lms_r2020 = mat3(
    +3.4366066943330784267,     -2.5064521186562698975,    +0.069845424323191470954,
    -0.79132955559892875305,    +1.9836004517922907339,    -0.19227089619336198096,
    -0.025949899690592673413,   -0.098913714711726441685,  +1.1248636144023191151);

/* LMS <-> ICTCP MATRICES */
const mat3 m_lms_ictcp = mat3(
    +0.5,                       +0.5,                      +0.0,
    +1.61376953125,             -3.323486328125,           +1.709716796875,
    +4.378173828125,            -4.24560546875,            -0.132568359375);
    
const mat3 m_ictcp_lms = mat3(
    +1.0,                       +0.0086090370379327566,    +0.11102962500302595655,
    +1.0,                       -0.0086090370379327566,    -0.11102962500302595655,
    +1.0,                       +0.560031335710679118,     -0.32062717498731885184);
 

/* COMMON FUNCTIONS */
float min3(vec3 x)
{
	return min(x.x, min(x.y, x.z));
}
float max3(vec3 x)
{
	return max(x.x, max(x.y, x.z));
}
float saturate(float x)
{
    return clamp(x, 0.0, 1.0);
}
vec2 saturate(vec2 x)
{
    return clamp(x, 0.0, 1.0);
}
vec3 saturate(vec3 x)
{
    return clamp(x, 0.0, 1.0);
}
vec4 saturate(vec4 x)
{
    return clamp(x, 0.0, 1.0);
}

vec3 con(vec3 x, float g, float c)
{
    return (x - g) * c + g;
}

/* https://github.com/CeeJayDK/SweetFX/blob/master/Shaders/Vibrance.fx */
float vibrance(vec3 x, float v)
{
    float lo, hi, s;

    lo = min3(x);
    hi = max3(x);
    s = hi - lo;
    return 1.0 + (v * (1.0 - (sign(v) * s)));
}

/* COLOR SPACE CONVERSION */
float lin_sRGB(float x)
{
    return x <= 0.0031308 ? x * 12.92 : pow(x, 1.0 / 2.4) * 1.055 - 0.055; 
}
float sRGB_lin(float x)
{
	return x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4);
}

vec3 lin_sRGB3(vec3 x)
{
    x.r = lin_sRGB(x.r);
    x.g = lin_sRGB(x.g);
    x.b = lin_sRGB(x.b);
    
    return x;
}
vec3 sRGB_lin3(vec3 x)
{
    x.r = sRGB_lin(x.r);
    x.g = sRGB_lin(x.g);
    x.b = sRGB_lin(x.b);
    
    return x;
}

/* https://www.arri.com/resource/blob/278790/bea879ac0d041a925bed27a096ab3ec2/2022-05-arri-logc4-specification-data.pdf */
float lin_LogC(float x)
{
    /* SKIPPING CONDITION CHECK SINCE SCENE COLOR IS ASSUMED POSITIVE */
    return (log2(LOGC_A * x + 64.0) - 6.0) / 14.0 * LOGC_B + LOGC_C;
}

float LogC_lin(float x)
{
    return x < 0.0 ? x * LOGC_S + LOGC_T : (exp2(14.0 * (x - LOGC_C) / LOGC_B + 6.0) - 64.0) / LOGC_A;

}

/* IT'S LOGC4 BUT I'M BAD AT NAMING THINGS */
vec3 lin_LogC3(vec3 x)
{
    x.r = lin_LogC(x.r);
    x.g = lin_LogC(x.g);
    x.b = lin_LogC(x.b);
    
    return x;
}
vec3 LogC_lin3(vec3 x)
{
    x.r = LogC_lin(x.r);
    x.g = LogC_lin(x.g);
    x.b = LogC_lin(x.b);
    
    return x;
}

float lin_PQ(float x)
{
    float p;

    p = pow(x / PQ_MAX, PQ_M1);

    return pow((PQ_C1 + PQ_C2 * p) / (1.0 + PQ_C3 * p), PQ_M2);
}

float PQ_lin(float x)
{
    float p;

    p = pow(x, 1.0 / PQ_M2);

    return pow(max(p - PQ_C1, 0.0) / (PQ_C2 - PQ_C3 * p), 1.0 / PQ_M1) * PQ_MAX;
}

vec3 lin_PQ3(vec3 x)
{
    x.r = lin_PQ(x.r);
    x.g = lin_PQ(x.g);
    x.b = lin_PQ(x.b);
    
    return x;
}

vec3 PQ_lin3(vec3 x)
{
    x.r = PQ_lin(x.r);
    x.g = PQ_lin(x.g);
    x.b = PQ_lin(x.b);
    
    return x;
}

vec3 r709_r2020(vec3 x)
{
    return x * m_r709_r2020;
}
vec3 r2020_r709(vec3 x)
{
    return x * m_r2020_r709;
}
vec3 r2020_lms(vec3 x)
{
    return x * m_r2020_lms;
}
vec3 lms_r2020(vec3 x)
{
    return x * m_lms_r2020;
}
vec3 lms_ictcp(vec3 x)
{
    return x * m_lms_ictcp;
}
vec3 ictcp_lms(vec3 x)
{
    return x * m_ictcp_lms;
}

vec3 r2020_ictcp(vec3 x)
{
    x = r2020_lms(x);
    x = lin_PQ3(x);
    x = lms_ictcp(x);

    return x;
}
vec3 ictcp_r2020(vec3 x)
{
    x = ictcp_lms(x);
    x = PQ_lin3(x);
    x = lms_r2020(x);

    return x;
}

/* https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html */
vec3 k_rgb(int x)
{
    vec3 r0;
    float t;

    t = float(x) * 0.01;

    if (t <= 66.0)
    {
        r0.r = 1.0;
        r0.g = saturate(0.3900815787690196 * log(t) - 0.6318414437886275);
    }
    else
    {
        r0.r = saturate(1.292936186062745 * pow(t - 60.0, -0.1332047592));
        r0.g = saturate(1.129890860895294 * pow(t - 60.0, -0.0755148492));
    }
    if (t >= 66.0)
        r0.b = 1.0;
    else
    {
        if (t <= 19.0)
            r0.b = 0.0;
        else
            saturate(r0.b = 0.543206789110196 * log(t - 10.0) - 1.19625408914);
    }
    return r0;
}

/* TONEMAPPING FROM https://www.shadertoy.com/view/llSyRD WITH A FEW TWEAKS */
float squish(float x)
{
	return 1.0 - exp(-x);
}
float tonemap(float x, float t)
{
	return (x < t) ? x : t + squish((x - t) / (1.0 - t)) * (1.0 - t);
}
vec3 tonemap3(vec3 x, float t)
{
	x.r = tonemap(x.r, t);
	x.g = tonemap(x.g, t);
	x.b = tonemap(x.b, t);
	return x;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 r0, r1, r2;
    vec3 t0, t1, t2;
    vec2 uv;
    float l0, l1;
    
    uv = fragCoord/iResolution.xy;
    
    r0 = texture(iChannel0, uv).rgb;
    r0 = sRGB_lin3(r0);
    r0 = r709_r2020(r0);
    r0 *= 1.0 + r0;   /* PSEUDO HDR SINCE IDK HOW TO LOAD AN HDR IMAGE, DON'T COPY PASTE THIS */
    r0 *= exp2(EExposure);
    
    t0 = k_rgb(ETemp);
    t0 = sRGB_lin3(t0);
    t0 = r709_r2020(t0);
    
    t1 = ETint;
    t1 = sRGB_lin3(t1);
    t1 = r709_r2020(t1);
    
    /* HACKY BUT CHEAP WAY TO PRESERVE LUMINANCE WITHOUT JUMPING MORE COLOR SPACES */
    r0 *= t0 / ((t0.r + t0.g + t0.b) * 0.3333333333333333);
    r0 *= t1 / ((t1.r + t1.g + t1.b) * 0.3333333333333333);
    
    r0 = lin_LogC3(r0);
    r0 = con(r0, EMidGray, EContrast);
    r0 = LogC_lin3(r0);
    
    r1 = r2020_ictcp(r0);
    r1.yz *= ESaturation;
    r1.yz *= vibrance(r0, EVibrance);
    r2 = ictcp_r2020(r1);    /* EARLY EXIT FOR PER-CHANNEL TONEMAPPING LATER */
    r1.yz *= 1.0 - (1.0 - exp2(dot(r0, L2020) * -EDesat));
    r0 = ictcp_r2020(r1);

    l0 = max3(r0);
    l1 = tonemap(l0, ECurve);
    r0 *= l1 / l0;
    r0 = mix(r0, tonemap3(r2, ECurve), EShift);
    
    r0 = saturate(r2020_r709(r0));
    r0 = lin_sRGB3(r0);
    fragColor = vec4(r0, texture(iChannel0, uv).a);
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}