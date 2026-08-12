#pragma header

#define PI 3.1415926535897932384626433832795
#define TWO_PI (PI * 2.0)

uniform float brightness;
uniform float threshold;
uniform float directions;
// El loader del editor entrega todas las propiedades del INI como Float.
uniform float quality;
uniform float size;

const int MAX_DIRECTIONS = 32;
const int MAX_QUALITY = 16;

void main(void) {
    vec2 uv = openfl_TextureCoordv.xy;
    vec4 color = flixel_texture2D(bitmap, uv);
    
    if (brightness <= 0.0 || size <= 0.0 || directions < 1.0 || quality < 1.0) {
        gl_FragColor = color;
        return;
    }

    float directionCount = clamp(floor(directions + 0.5), 1.0, float(MAX_DIRECTIONS));
    float qualityCount = clamp(floor(quality + 0.5), 1.0, float(MAX_QUALITY));
    vec4 bloom = vec4(0.0);
    float weightSum = 0.0;

    for (int directionIndex = 0; directionIndex < MAX_DIRECTIONS; directionIndex++) {
        if (float(directionIndex) >= directionCount) break;
        float d = TWO_PI * float(directionIndex) / directionCount;

        for (int qualityIndex = 1; qualityIndex <= MAX_QUALITY; qualityIndex++) {
            if (float(qualityIndex) > qualityCount) break;
            float samplePosition = float(qualityIndex) / qualityCount;
            float offset = samplePosition * size;
            float x_offset = (sin(d) * offset) / openfl_TextureSize.y;
            float y_offset = (cos(d) * offset) / openfl_TextureSize.x;
            vec2 sampleUV = clamp(uv + vec2(x_offset, y_offset), vec2(0.0), vec2(1.0));

            // Sample only the highlight areas
            vec4 sampleColor = max(flixel_texture2D(bitmap, sampleUV) - threshold, 0.0);
            float weight = exp(-2.0 * samplePosition); // Smooth falloff
            bloom += sampleColor * weight;
            weightSum += weight;
        }
    }

    if (weightSum > 0.0) {
        bloom /= weightSum;
    }

    gl_FragColor = color + (bloom * brightness);
}
