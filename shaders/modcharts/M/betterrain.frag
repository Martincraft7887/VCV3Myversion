// Downward rain droplets based on Voiid Chronicles' RainEffect.
// Keeps only the droplets and their localized refraction.

#pragma header

uniform float iTime;
uniform float rainAmount;
uniform float speed;
uniform float dropScale;
uniform float refraction;

vec2 rainRand(vec2 cell) {
    mat2 randomMatrix = mat2(12.9898, 0.16180, 78.233, 0.31415);
    return fract(sin(randomMatrix * cell) * vec2(43758.5453, 14142.1));
}

vec2 rainNoise(vec2 point) {
    vec2 cell = floor(point);
    vec2 blend = fract(point);
    blend = 3.0 * blend * blend - 2.0 * blend * blend * blend;

    vec2 a = rainRand(cell);
    vec2 b = rainRand(cell + vec2(1.0, 0.0));
    vec2 c = rainRand(cell + vec2(0.0, 1.0));
    vec2 d = rainRand(cell + vec2(1.0, 1.0));
    return mix(mix(a, b, blend.x), mix(c, d, blend.x), blend.y);
}

vec2 roundCell(vec2 value) {
    return floor(value + 0.5);
}

void main() {
    vec2 screenUV = openfl_TextureCoordv;
    vec4 source = flixel_texture2D(bitmap, screenUV);
    float amount = clamp(rainAmount, 0.0, 1.0);

    if (amount <= 0.0001 || abs(refraction) <= 0.0001) {
        gl_FragColor = source;
        return;
    }

    vec2 resolution = max(openfl_TextureSize, vec2(1.0));
    float animationTime = iTime * speed;

    // Texture Y grows downward in CNE. Subtracting time from the sampled
    // coordinate makes the visible pattern travel downward.
    vec2 movingUV = screenUV;
    movingUV.y -= animationTime * 0.12;

    vec2 displacement = rainNoise(movingUV * 20.0);
    vec2 referenceResolution = vec2((resolution.x / resolution.y) * 720.0, 720.0);
    referenceResolution *= max(dropScale, 0.05);

    float dropMask = 0.0;
    vec2 refractionOffset = vec2(0.0);

    for (int layer = 0; layer < 4; layer++) {
        float inverseSize = 4.0 - float(layer);
        vec2 grid = referenceResolution * inverseSize * 0.015;
        vec2 phase = 6.2831853 * movingUV * grid + (displacement - 0.5) * 2.0;
        vec2 sineShape = sin(phase);

        vec2 stableUV = roundCell(movingUV * grid - 0.25) / grid;
        vec4 randomData = vec4(rainNoise(stableUV * 200.0), rainNoise(stableUV));
        float life = max(0.0, 1.0 - fract(animationTime * (randomData.b + 0.1) + randomData.g) * 2.0);
        float shape = (sineShape.x + sineShape.y) * life;
        float density = (5.0 - inverseSize) * 0.08 * amount;

        if (randomData.r < density && shape > 0.5) {
            vec3 dropNormal = normalize(-vec3(cos(phase), mix(0.2, 2.0, max(shape - 0.5, 0.0))));
            float localMask = smoothstep(0.5, 1.1, shape);
            vec2 localOffset = -dropNormal.xy * (0.035 * refraction);
            refractionOffset = mix(refractionOffset, localOffset, localMask);
            dropMask = max(dropMask, localMask);
        }
    }

    vec2 refractedUV = clamp(screenUV + refractionOffset, vec2(0.001), vec2(0.999));
    vec4 refracted = flixel_texture2D(bitmap, refractedUV);
    vec3 color = mix(source.rgb, refracted.rgb, dropMask);
    gl_FragColor = vec4(color, source.a);
}
