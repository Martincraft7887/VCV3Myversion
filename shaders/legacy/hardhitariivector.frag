//hardhitariivector by Orsty_Mania

#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
#define texture flixel_texture2D
uniform float strength;

mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

float hash21(vec2 p){
    return fract(sin(dot(p, vec2(27.917, 57.543)))*43758.5453);
}

float dist(vec2 p, float rnd){
    #ifdef LEAFY
    	p = rot2(6.2831*rnd + fract(rnd*57. + .37)*iTime/2.)*p;
        #if 1
        float r = length(p) + sqrt(abs(p.x/8.));
        #else
        float r = pow(dot(pow(abs(p), vec2(2.)), vec2(1)), 1./2.) + abs(p.x);
        #endif
        return r/1.4142 - .0;
    #else 
        return length(p);
    #endif
}

float sBox(vec2 p, vec2 b){
  vec2 d = abs(p) - b;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

vec2 PipePattern(vec2 p, float lw){
    float d = 1e5, d2 = 1e5;
	vec2 ip = floor(p);
    p -= ip + .5;
    float rnd = hash21(ip + 12.53); 
    float rnd2 = hash21(ip); 
    if(rnd2>.6){
        p.y *= (rnd>.5)? -1. : 1.;
        p = p.x>-p.y? p : -p;
        float dc = abs(length(p - .5) - .5);
        d = min(d, dc);
    }
    else if(rnd2>.3){
        p = (fract(rnd*151. + .76)>.5)? p.yx : p;
        d = min(d, sBox(p, vec2(0, .5)));
        p.x = abs(p.x);
        d = min(d, length(p - vec2(.5, 0)));            
    }
    else {
        p = (fract(rnd*57. + .34)>.5)? p.yx : p;
        d = min(d, sBox(p, vec2(0, .5)));
        d2 = min(d2, sBox(p, vec2(.5, 0)));
    }
    d -= lw/2.;
    d2 -= lw/2.;
    return vec2(d, d2);
}

vec2 hash22(vec2 p) { 
    float n = sin(dot(p, vec2(41, 289)));
    p = fract(vec2(262144, 32768)*n);
    return sin(p*6.2831853 + iTime); 
}

float n2D3G( in vec2 p ){
    vec2 i = floor(p); p -= i;
    vec4 v;
    v.x = dot(hash22(i), p);
    v.y = dot(hash22(i + vec2(1, 0)), p - vec2(1, 0));
    v.z = dot(hash22(i + vec2(0, 1)), p - vec2(0, 1));
    v.w = dot(hash22(i + 1.), p - 1.);
#if 1
    p = p*p*p*(p*(p*6. - 15.) + 10.);
#else
    p = p*p*(3. - 2.*p);
#endif
    return mix(mix(v.x, v.y, p.x), mix(v.z, v.w, p.x), p.y);
}

float n2D(vec2 p) {
	vec2 i = floor(p); p -= i; p *= p*(3. - p*2.);  
	return dot(mat2(fract(sin(vec4(0, 1, 113, 114) + dot(i, vec2(1, 113)))*43758.5453))*
                vec2(1. - p.y, p.y), vec2(1. - p.x, p.x) );
}

float sFract(float x, float sf){
    x = fract(x);
    return min(x, (1. - x)*x*sf);
}

vec3 GrungeTex(vec2 p){
    float c = n2D(p*3.)*.57 + n2D(p*7.)*.28 + n2D(p*15.)*.15;
    vec3 col = mix(vec3(.25, .1, .02), vec3(.35, .5, .65), c);
    col *= n2D(p*vec2(150., 350.))*.5 + .5; 
    col = mix(col, col*vec3(.75, .95, 1.2), sFract(c*4., 12.));
    col = mix(col, col*vec3(1.2, 1, .8)*.8, sFract(c*5. + .35, 12.)*.5);
    c = n2D(p*8. + .5)*.7 + n2D(p*18. + .5)*.3;
    c = c*.7 + sFract(c*5., 16.)*.3;
    col = mix(col*.6, col*1.4, c);
    return clamp(col, 0., 1.);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    vec2 uv = (fragCoord - iResolution.xy * 0.5) / min(800.0, iResolution.y);
    float time = -iTime;

    float gSc = 5.0;
    vec2 p = uv * gSc + vec2(0.5, 0.0) * time;

    const float lw = 0.425;
    const float ew = 0.04;
    float sf = 1.0 / iResolution.y * gSc;

    vec2 df = PipePattern(p, lw);
    vec2 dfSh = PipePattern(p - vec2(-0.03, -0.05) * 2.0, lw);
    vec2 dfHi = PipePattern(p - vec2(0.03, 0.05) * 1.1, lw);

    vec3 tx = GrungeTex(uv * 1.0 + 0.5);
    tx = smoothstep(-0.1, 0.5, tx);
    tx = mix(tx, vec3(1.0) * dot(tx, vec3(0.299, 0.587, 0.114)), 0.75);
    tx *= vec3(1.0, 0.9, 0.8);

    vec3 tx2 = GrungeTex(p / gSc * 1.0 + 0.5);
    tx2 = smoothstep(-0.1, 0.5, tx2);
    tx2 = mix(tx2, vec3(1.0) * dot(tx2, vec3(0.299, 0.587, 0.114)), 0.75);
    tx2 *= vec3(1.0, 0.9, 0.8);

    vec3 lCol = tx2 * 2.2 * vec3(0.5, 0.05, 0.3);
    lCol = mix(lCol, lCol.xzy, uv.y * 0.25 + 0.25);

    vec3 outerCol = vec3(0.5);

    vec3 col = texture(bitmap, fragCoord / iResolution.xy).rgb;

    float cir = 1e5, cirHi = 1e5, cirSh = 1e5;
    const float sc = 3.5;

    vec3 gr = dot(tx, vec3(0.299, 0.587, 0.114)) * vec3(1.5);
    vec3 co = tx * 2.2 * vec3(0.6, 0.05, 0.3);
    co = mix(co, co.xzy, uv.y * 0.25 + 0.25);

    col = mix(col, vec3(0), (1.0 - smoothstep(0.0, sf * 4.0, min(dfSh.x, dfSh.y) - ew * 1.5)) * 0.75);
    col = mix(col, outerCol, (1.0 - smoothstep(0.0, sf, df.x)));
    col = mix(col, vec3(0), (1.0 - smoothstep(0.0, sf, df.x + ew * 1.5)));

    float dHiX = min(dfHi.x, dfHi.y); dHiX = max(dHiX, df.x - ew * 0.5);
    col = mix(col, lCol / 2.0, (1.0 - smoothstep(0.0, sf, dHiX + ew * 3.8)) * 0.95);
    col = mix(col, vec3(0.6), (1.0 - smoothstep(0.0, sf, dHiX + ew * 4.8)) * 0.95);

    float dShY = max(dfSh.y, max(dfSh.x - ew * 1.5, df.x + ew * 1.5));
    col = mix(col, vec3(0), (1.0 - smoothstep(0.0, sf * 4.0, dShY - ew * 1.5)) * 0.75);
    col = mix(col, outerCol, (1.0 - smoothstep(0.0, sf, df.y)));
    col = mix(col, vec3(0), (1.0 - smoothstep(0.0, sf, df.y + ew * 1.5)));
    col = mix(col, lCol, (1.0 - smoothstep(0.0, sf, df.y + ew * 3.5)));

    float dHiY = min(dfHi.y, max(dfHi.x, -df.x));
    dHiY = max(dHiY, df.y - ew * 0.5);
    col = mix(col, lCol / 2.0, (1.0 - smoothstep(0.0, sf, dHiY + ew * 3.8)) * 0.95);
    col = mix(col, vec3(0.6), (1.0 - smoothstep(0.0, sf, dHiY + ew * 4.8)) * 0.95);

    uv = fragCoord / iResolution.xy;

    vec4 sceneColor = texture(bitmap, fragCoord / iResolution.xy);
    col = mix(sceneColor.rgb, col, strength);

    fragColor = vec4(clamp(col, 0.0, 1.0), sceneColor.a);
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}