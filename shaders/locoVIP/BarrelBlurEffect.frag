#pragma header

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001

uniform float barrel;
uniform float zoom;
uniform bool doChroma;
uniform float angle;
uniform float iTime;

uniform float x;
uniform float y;

uniform float warp;
uniform float dist;

uniform float Xdirection;
uniform float Ydirection;
uniform vec3 rotation;

uniform bool repeatNormal;

#define iResolution vec3(openfl_TextureSize,0.)
#define texture flixel_texture2D
#define iChannel0 bitmap

vec4 spectrum_offset_rgb(float t) {
    if (!doChroma) return vec4(1.0);
    float t0 = 3.0 * t - 1.5;
    vec3 ret = clamp(vec3(-t0, 1.0 - abs(t0), t0), 0.0, 1.0);
    return vec4(ret, 1.0);
}

vec2 brownConradyDistortion(vec2 uv, float distortion) {
    uv = uv * 2.0 - 1.0;
    float barrelDistortion1 = 0.1 * distortion;
    float barrelDistortion2 = -0.025 * distortion;
    float r2 = dot(uv, uv);
    uv *= 1.0 + barrelDistortion1 * r2 + barrelDistortion2 * r2 * r2;
    return uv * 0.5 + 0.5;
}

vec2 distort(vec2 uv, float t, vec2 min_distort, vec2 max_distort) {
    vec2 d = mix(min_distort, max_distort, t);
    return brownConradyDistortion(uv, 75.0 * d.x);
}

float nrand(vec2 n) {
    return fract(sin(dot(n.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 repeatUV(vec2 uv) {

    if (repeatNormal) {
        uv = fract(uv);
    } else {
        if ((uv.x > 1.0 || uv.x < 0.0) && abs(mod(uv.x, 2.0)) > 1.0)
            uv.x = (0.0 - uv.x) + 1.0;

        if ((uv.y > 1.0 || uv.y < 0.0) && abs(mod(uv.y, 2.0)) > 1.0)
            uv.y = (0.0 - uv.y) + 1.0;

        uv = fract(uv);
    }

    return clamp(uv, 0.0, 0.998);
}

vec4 render(vec2 uv) {
    uv.x += x;
    uv.y += y;
    return texture(iChannel0, repeatUV(uv));
}

mat3 rotateX(float a){float c=cos(a),s=sin(a);return mat3(1,0,0,0,c,-s,0,s,c);}
mat3 rotateY(float a){float c=cos(a),s=sin(a);return mat3(c,0,s,0,1,0,-s,0,c);}
mat3 rotateZ(float a){float c=cos(a),s=sin(a);return mat3(c,-s,0,s,c,0,0,0,1);}

float plane(vec3 p, vec3 offset){return p.z;}
float GetDist(vec3 p){return plane(p, vec3(0.));}

float RayMarch(vec3 ro, vec3 rd){
    float dO=0.;
    for(int i=0;i<MAX_STEPS;i++){
        vec3 p=ro+rd*dO;
        float dS=GetDist(p);
        dO+=dS;
        if(dO>MAX_DIST||abs(dS)<SURF_DIST) break;
    }
    return dO;
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z){
    vec3 f=normalize(l-p), r=normalize(cross(vec3(0.,1.,0.),f)), u=cross(f,r);
    vec3 c=f*z, i=c+uv.x*r+uv.y*u;
    return normalize(i);
}

void main() {
    vec2 uv = openfl_TextureCoordv.xy;
    vec4 originalCol = texture(iChannel0, clamp(uv, vec2(0.001), vec2(0.999)));
    float aspect = iResolution.x / iResolution.y;

    uv -= 0.5;
    uv.x = -uv.x;
    uv.y /= aspect;

    float rad = -radians(angle);
    mat2 rot = mat2(cos(rad), -sin(rad), sin(rad), cos(rad));
    uv = rot * uv;

    uv *= zoom;
    float len = length(uv);
    uv += uv * (warp * len * len);

    uv.y *= aspect;
    uv += 0.5;

    vec3 ro = vec3(Xdirection, Ydirection, 2.0);
    ro = ro * rotateX(rotation.x) * rotateY(rotation.y) * rotateZ(rotation.z);
    vec3 rd = GetRayDir(uv - vec2(0.5), ro, vec3(0.), 1.0);

    vec4 col = originalCol;
    float d = RayMarch(ro, rd);

    if (d < MAX_DIST) {
        vec3 p = ro + rd * d;
        vec2 tuv = clamp(vec2(p.x, p.y) * 0.5 + 0.5, vec2(0.001), vec2(0.999));

        const float MAX_DIST_PX = 50.0;
        float max_distort_px = MAX_DIST_PX * barrel;
        vec2 max_distort = vec2(max_distort_px) / iResolution.xy;
        vec2 min_distort = 0.5 * max_distort;

        if (dist == 0.0) {
            const int num_iter = 7;
            const float stepsiz = 1.0 / (float(num_iter) - 1.0);
            float rnd = nrand(tuv + fract(iTime));
            float t = rnd * stepsiz;
            vec4 sumcol = vec4(0.0);
            vec3 sumw = vec3(0.0);

            for (int i = 0; i < num_iter; i++) {
                vec4 w = spectrum_offset_rgb(t);
                sumw += w.rgb;
                vec2 uvd = clamp(distort(tuv, t, min_distort, max_distort), vec2(0.001), vec2(0.999));
                sumcol += w * render(uvd);
                t += stepsiz;
            }

            sumcol.rgb /= sumw;
            col = vec4(sumcol.rgb, sumcol.a / float(num_iter));
        } else {
            vec2 p2 = (tuv - 0.5) * 2.0;
            float theta = atan(p2.y, p2.x);
            float rd2 = length(p2);
            vec4 channelFactor = vec4(0.9, 1.0, 1.3, 1.0);
            vec4 strength = dist * channelFactor;
            vec4 ru = rd2 * (1.0 + strength * rd2 * rd2);
            vec2 dir = vec2(cos(theta), sin(theta));

            vec2 qr = clamp(dir * ru.x / 2.0 + 0.5, vec2(0.001), vec2(0.999));
            vec2 qg = clamp(dir * ru.y / 2.0 + 0.5, vec2(0.001), vec2(0.999));
            vec2 qb = clamp(dir * ru.z / 2.0 + 0.5, vec2(0.001), vec2(0.999));
            vec2 qa = clamp(dir * ru.w / 2.0 + 0.5, vec2(0.001), vec2(0.999));

            col = vec4(
                render(qr).x,
                render(qg).y,
                render(qb).z,
                render(qa).w
            );
        }
    }

    gl_FragColor = col;
}
