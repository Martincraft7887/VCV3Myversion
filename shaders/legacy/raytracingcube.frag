// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define round(a) floor(a + 0.5)
#define texture flixel_texture2D
#define iResolution openfl_TextureSize
uniform float iTime;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

float planeIntersection(vec3 N,vec3 V,vec3 pos){
	float distToPlane = -dot(pos,N);
	float rayDotPlane = -dot(V,N);
    if (rayDotPlane > 0. && distToPlane > 0.)
        return distToPlane/rayDotPlane;
    else return 0.;
}

vec2 getUV(vec3 perpX, vec3 perpY, vec3 pos){
	return vec2(dot(perpX,pos),dot(perpY,pos));
}

vec3 planeColor(vec3 V,vec3 N,vec3 lightVec,vec2 uv){
    float lightDist = length(lightVec);
    float brightness = 100.*dot(N,lightVec)/(lightDist * lightDist * lightDist);
    vec3 reflected = reflect(V,N);
    float threshold = 1./lightDist/lightDist;
    //float shine = smoothstep(1.- 1.5*threshold,1.- 0.2*threshold,dot(reflected,lightVec/lightDist));
    float shine = 100.*pow(max(0.,dot(reflected,lightVec/lightDist)),50.)/lightDist/lightDist;
    return (brightness+shine)*texture(iChannel0, 0.5*uv+0.5).xyz;
}

vec4 boxColor(vec3 viewingNormal, vec3 lightPos, vec3 boxPos, vec3 planeX,vec3 planeY, vec3 planeZ){
    
    for (int i = 0; i < 2; ++i){
        vec3 planePos = boxPos + planeZ;
        float t = planeIntersection(planeZ,viewingNormal,planePos);
        vec2 uv;
        if (t > 0.){
            vec3 pos = t*viewingNormal;

            uv = getUV(planeX,planeY,pos - planePos);

            if (uv.x < length(planeX) && uv.x > -length(planeX) && uv.y < length(planeY) && uv.y > -length(planeY)){
                return vec4(planeColor(viewingNormal,planeZ,lightPos-pos,uv),t);
            }
        }
        planePos = boxPos + planeX;
        t = planeIntersection(planeX,viewingNormal,planePos);
        if (t > 0.){
            vec3 pos = t*viewingNormal;

            uv = getUV(planeZ,planeY,pos - planePos);

            if (uv.x < length(planeZ) && uv.x > -length(planeZ) && uv.y < length(planeY) && uv.y > -length(planeY)){
                return vec4(planeColor(viewingNormal, planeX,lightPos-pos,uv),t);
            }
        }

        planePos = boxPos + planeY;
        t = planeIntersection(planeY,viewingNormal,planePos);
        if (t > 0.){
            vec3 pos = t*viewingNormal;

            uv = getUV(planeX,planeZ,pos - planePos);

            if (uv.x < length(planeZ) && uv.x > -length(planeZ) && uv.y < length(planeX) && uv.y > -length(planeX)){
                return vec4(planeColor(viewingNormal,planeY,lightPos-pos,uv),t);
            }
        }

        planeX *= -1.;
        planeY *= -1.;
        planeZ *= -1.;
    }
    return vec4(0);
}
    
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy/iResolution.x;
    float aspect = iResolution.x/iResolution.y;
    
    //Based on uv
    vec3 viewingNormal = normalize( vec3( uv-vec2(0.5,0.5/aspect),1));
    vec3 lightPos = vec3(-1,-1,2);
    vec3 boxPos = vec3(0,-1,15);
    vec3 planeZ = normalize(vec3(cos(iTime),1,sin(iTime)));
    vec3 planeX = normalize(cross(planeZ,vec3(1,0,0)));
    vec3 planeY = cross(planeZ,planeX);
    vec4 boxCol1= boxColor(viewingNormal,lightPos,boxPos,planeX,planeY,planeZ);
    boxPos += planeZ*4.;
    vec3 colour = vec3(0);
        colour += boxCol1.xyz;
	fragColor = vec4(colour,texture(iChannel0, uv).a);
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}