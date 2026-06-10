#pragma header

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001

#define S smoothstep
#define T iTime

uniform vec3 rotation;
uniform vec3 iResolution;
uniform float Xdirection;
uniform float Ydirection;
uniform float direction360;
uniform float Ydirection360;

mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1., 0., 0.),
        vec3(0., c, -s),
        vec3(0., s, c)
    );
}

mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0., s),
        vec3(0., 1., 0.),
        vec3(-s, 0., c)
    );
}

mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0.),
        vec3(s, c, 0.),
        vec3(0., 0., 1.)
    );
}

mat3 rotate360(float angle) {
    float rad = radians(angle);
    float c = cos(rad);
    float s = sin(rad);
    return mat3(
        vec3(c, 0., s),
        vec3(0., 1., 0.),
        vec3(-s, 0., c)
    );
}

float GetDist(vec3 p) {
    return p.z;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO = 0.;
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dO;
        float dS = GetDist(p);
        dO += dS; 
        if(dO > MAX_DIST || abs(dS) < SURF_DIST) break;
    }
    return dO;
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l - p);
    vec3 r = normalize(cross(vec3(0.0, 1.0, 0.0), f));
    vec3 u = cross(f, r);
    vec3 c = f * z;
    vec3 i = c + uv.x * r + uv.y * u;
    return normalize(i);
}

vec2 repeat(vec2 uv) {
    if (Xdirection != 0.0 || Ydirection != 0.0) {
        if ((uv.x > 1.0 || uv.x < 0.0) && abs(mod(uv.x, 2.0)) > 1.0)
            uv.x = (0.0 - uv.x) + 1.0;
        if ((uv.y > 1.0 || uv.y < 0.0) && abs(mod(uv.y, 2.0)) > 1.0)
            uv.y = (0.0 - uv.y) + 1.0;
        return vec2(mod(uv.x, 1.0), mod(uv.y, 1.0));
    }
    return uv;
}

vec2 repeatInvisible(vec2 uv) {
    if (direction360 != 0.0) {
        uv = mod(uv, 1.0);
        if (uv.x < 0.0) uv.x += 1.0;
        if (uv.y < 0.0) uv.y += 1.0;

        uv = mix(vec2(0.5), uv, 0.2); 
    }
    return uv;
}

void main() {
    vec2 center = vec2(0.5, 0.5);
    vec2 uv = openfl_TextureCoordv.xy - center;
    uv.x = -uv.x;

    float adjustedDirection360 = direction360;

    vec3 ro = vec3(Xdirection, Ydirection, 2.0);
    ro = ro * rotate360(adjustedDirection360);

    if (mod(openfl_TextureCoordv.x, 1.0) == openfl_TextureCoordv.x &&
        mod(openfl_TextureCoordv.y, 1.0) == openfl_TextureCoordv.y) {
        ro = ro * rotate360(direction360);
    }

    ro = ro * rotateX(rotation.x) * rotateY(rotation.y) * rotateZ(rotation.z);

    float normalizedDirection = mod(direction360, 360.0);
    adjustedDirection360 = direction360;
    float normalizedDirectionY = mod(Ydirection360, 360.0);

    if (normalizedDirection >= 45.0 && normalizedDirection < 135.0) {
        ro = ro * rotateX(3.14159);  
        adjustedDirection360 = -134.0; 
        uv.x = -uv.x;
    } else if (normalizedDirection >= 225.0 && normalizedDirection < 315.0) {
        ro = ro * rotateX(3.14159);
        adjustedDirection360 = -134.0;
        uv.x = -uv.x;
    }

if (normalizedDirection >= -45.0 && normalizedDirection < -135.0) {
        ro = ro * rotateX(3.14159);  
        adjustedDirection360 = 134.0; 
        uv.x = -uv.x;
    } else if (normalizedDirection >= -225.0 && normalizedDirection < -315.0) {
        ro = ro * rotateX(3.14159);
        adjustedDirection360 = 134.0;
        uv.x = -uv.x;
    }

    if (Ydirection360 != 0.0) {
        ro = ro * rotateX(radians(Ydirection360));
    }

    if (normalizedDirectionY >= 90.0 && normalizedDirectionY < 180.0) {
        ro = ro * rotateY(3.14159);  
        adjustedDirection360 = 179.0; 
        uv.y = -uv.y;
    } else if (normalizedDirectionY >= 270.0 && normalizedDirectionY < 360.0) { 
        adjustedDirection360 = 179.0;
          }

    if (normalizedDirectionY >= 180.0 && normalizedDirectionY < 270.0) {
        ro = ro * rotateY(3.14159);   
        uv.y = -uv.y;
    } else if (normalizedDirectionY >= 360.0 && normalizedDirectionY < 450.0) {
        ro = ro * rotateY(3.14159);
        uv.y = -uv.y;
    }

    if (normalizedDirectionY >= -90.0 && normalizedDirectionY < -180.0) {
        ro = ro * rotateY(3.14159);  
        adjustedDirection360 = 179.0; 
        uv.y = -uv.y;
    } else if (normalizedDirectionY >= -270.0 && normalizedDirectionY < -360.0) {
        ro = ro * rotateY(3.14159);
        adjustedDirection360 = 179.0;
        uv.y = -uv.y;
    }

    vec3 rd = GetRayDir(uv, ro, vec3(0.0, 0., 0.0), 1.0);
    vec4 col = vec4(0.0);

    float d = RayMarch(ro, rd);

    if(d < MAX_DIST) {
        vec3 p = ro + rd * d;
        uv = vec2(p.x, p.y) * 0.5;
        uv += center;

        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            col = flixel_texture2D(bitmap, repeatInvisible(uv));
            col.a = 0.0; 
        } else {
            col = flixel_texture2D(bitmap, repeat(uv));
        }
    }

    gl_FragColor = col;
}