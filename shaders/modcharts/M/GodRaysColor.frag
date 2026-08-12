#pragma header

uniform float iTime;
uniform float threshold;
uniform vec3 lightcol;
uniform float bright;

// 64 keeps the effect smooth without the 130 texture reads per pixel from the
// original version, which was particularly expensive in editor preview mode.
const int NSAMPLES = 64;

vec4 preprocessTexture(vec2 uv) {
    uv.x += sin(iTime + (uv.y * 4.0)) * 0.001;
    uv.y += cos(iTime + (uv.x * 4.0)) * 0.001;

    vec4 source = flixel_texture2D(bitmap, clamp(uv, vec2(0.0), vec2(1.0)));
    float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
    if (luminance > clamp(threshold, 0.0, 1.0)) {
        vec3 rayColor = clamp(lightcol / 255.0, vec3(0.0), vec3(1.0));
        return vec4(rayColor * source.a, source.a);
    }

    return vec4(0.0);
}

vec3 crepuscularRays(vec2 texCoords, vec2 lightPosition) {
    float intensity = max(bright, 0.0);
    float decay = clamp(0.905 * (1.0 + ((1.0 - intensity) / 20.0)), 0.0, 0.999);
    float density = 0.54;
    float weight = max((0.16 + sin(iTime) * 0.02) * intensity, 0.0);

    vec2 sampleCoords = texCoords;
    vec2 deltaTexCoord = (sampleCoords - lightPosition) * (density / float(NSAMPLES));
    float illuminationDecay = 1.0;
    vec3 rays = preprocessTexture(sampleCoords).rgb * 0.1;

    float jitter = fract(sin(dot(texCoords, vec2(12.9898, 78.233))) * 43758.5453);
    sampleCoords += deltaTexCoord * (jitter * 0.9);

    for (int i = 0; i < NSAMPLES; i++) {
        sampleCoords -= deltaTexCoord;
        vec3 sampleColor = preprocessTexture(sampleCoords).rgb * 0.4;
        rays += sampleColor * illuminationDecay * weight;
        illuminationDecay *= decay;
    }

    return rays;
}

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec4 source = flixel_texture2D(bitmap, uv);

    if (bright <= 0.0) {
        gl_FragColor = source;
        return;
    }

    vec2 lightPosition = vec2(
        0.5 + cos(iTime + 0.16) * 0.04,
        0.3 + sin(iTime * 0.5) * 0.03
    );
    vec3 rays = crepuscularRays(uv, lightPosition);
    gl_FragColor = vec4(clamp(source.rgb + rays, vec3(0.0), vec3(1.0)), source.a);
}
