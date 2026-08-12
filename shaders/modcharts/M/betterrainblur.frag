// Downward rain droplets based on Voiid Chronicles' RainEffect.
// Uses a GLSL 1.20-compatible manual blur; no mipmaps or textureLod.

#pragma header

uniform float iTime;
uniform float rainAmount;
uniform float speed;
uniform float dropScale;
uniform float refraction;
uniform float blurAmount;

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

vec4 blur9(vec2 uv, vec2 resolution, float radius) {
    vec2 offset = vec2(max(radius, 0.0)) / resolution;
    vec4 result = flixel_texture2D(bitmap, uv) * 4.0;

    result += flixel_texture2D(bitmap, clamp(uv + vec2(offset.x, 0.0), vec2(0.001), vec2(0.999))) * 2.0;
    result += flixel_texture2D(bitmap, clamp(uv - vec2(offset.x, 0.0), vec2(0.001), vec2(0.999))) * 2.0;
    result += flixel_texture2D(bitmap, clamp(uv + vec2(0.0, offset.y), vec2(0.001), vec2(0.999))) * 2.0;
    result += flixel_texture2D(bitmap, clamp(uv - vec2(0.0, offset.y), vec2(0.001), vec2(0.999))) * 2.0;

    result += flixel_texture2D(bitmap, clamp(uv + offset, vec2(0.001), vec2(0.999)));
    result += flixel_texture2D(bitmap, clamp(uv - offset, vec2(0.001), vec2(0.999)));
    result += flixel_texture2D(bitmap, clamp(uv + vec2(offset.x, -offset.y), vec2(0.001), vec2(0.999)));
    result += flixel_texture2D(bitmap, clamp(uv + vec2(-offset.x, offset.y), vec2(0.001), vec2(0.999)));
    return result / 16.0;
}

void main() {
    vec2 screenUV = openfl_TextureCoordv;
    vec4 source = flixel_texture2D(bitmap, screenUV);
    vec2 resolution = max(openfl_TextureSize, vec2(1.0));
    float amount = clamp(rainAmount, 0.0, 1.0);
    float blurRadius = max(blurAmount, 0.0);

    if (amount <= 0.0001 && blurRadius <= 0.0001) {
        gl_FragColor = source;
        return;
    }

    float dropMask = 0.0;
    vec2 refractionOffset = vec2(0.0);

    if (amount > 0.0001) {
        float animationTime = iTime * speed;
        vec2 movingUV = screenUV;
        movingUV.y -= animationTime * 0.12;

        vec2 displacement = rainNoise(movingUV * 20.0);
        vec2 referenceResolution = vec2((resolution.x / resolution.y) * 720.0, 720.0);
        referenceResolution *= max(dropScale, 0.05);

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
    }

    vec2 refractedUV = clamp(screenUV + refractionOffset, vec2(0.001), vec2(0.999));
    vec4 clearImage = flixel_texture2D(bitmap, refractedUV);
    vec4 blurredImage = blurRadius <= 0.0001 ? clearImage : blur9(refractedUV, resolution, blurRadius);
    vec3 color = mix(blurredImage.rgb, clearImage.rgb, dropMask);
    gl_FragColor = vec4(color, source.a);
}
