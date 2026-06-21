#pragma header

#define iChannel0 bitmap
#define texture flixel_texture2D
#define iResolution vec3(openfl_TextureSize, 0.)

uniform float u_pointCount;
uniform float strength;
uniform float zoom;

#define MAX_POINTS 30

float random(vec2 p){
    return fract(sin(dot(p.xy, vec2(12.9898,78.233))) * 43758.5453);
}

vec2 random2(vec2 p){
    float r = random(p);
    return vec2(r, random(p + r));
}

vec4 breakGlass(vec2 uv, float str) {
    vec2 point[MAX_POINTS];
    int POINTS = int(u_pointCount);
    for(int i = 0; i < MAX_POINTS; i++){
        if(i >= POINTS) break;
        point[i] = random2(vec2(float(i)));
    }

    float breakTime = max(str, 0.0);

    vec4 col = texture(iChannel0, uv);
    if(breakTime > 0.0){
        col = vec4(0.0);

        for(int i = 0; i < MAX_POINTS; i++){
            if(i >= POINTS) break;

            vec2 dir = normalize(point[i] - vec2(0.5));
            float v = (0.5 + random(dir) * 0.5) * 0.2;
            vec2 offset = dir * v * breakTime;

            mat3 T = mat3(1.0, 0.0, 0.0,
                          0.0, 1.0, 0.0,
                         -offset, 1.0);

            vec2 U = (T * vec3(uv, 1.0)).xy;

            bool match = true;
            if(U.x >= 0.0 && U.x <= 1.0 && U.y >= 0.0 && U.y <= 1.0){
                for(int j = 0; j < MAX_POINTS; j++){
                    if(j >= POINTS) break;
                    float dist = distance(U, point[j]);
                    if(dist < distance(U, point[i])) match = false;
                }
            } else {
                match = false;
            }

            if(match){
                col = texture(iChannel0, U);
                break;
            }
        }
    }

    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = fragCoord / iResolution.xy;

    vec2 center = vec2(0.5);
    uv = (uv - center) / zoom + center;

    fragColor = breakGlass(uv, strength);
}

void main(){
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}