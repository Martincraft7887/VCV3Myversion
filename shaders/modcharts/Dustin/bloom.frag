#pragma header

#define PI 3.1415926535897932384626433832795
#define TWO_PI (PI * 2.0)

uniform float brightness;
uniform float directions;
// El loader del editor entrega todas las propiedades del INI como Float.
uniform float quality;
uniform float size;

const int MAX_DIRECTIONS = 32;
const int MAX_QUALITY = 16;

void main(void) {
    vec2 uv = openfl_TextureCoordv.xy;
    vec4 color = flixel_texture2D(bitmap, uv);
    vec4 bloom = color;

    // Evita divisiones invalidas y deja el shader neutro con sus defaults.
    if (brightness <= 0.0 || size <= 0.0 || directions < 1.0 || quality < 1.0) {
        gl_FragColor = color;
        return;
    }

    float directionCount = clamp(floor(directions + 0.5), 1.0, float(MAX_DIRECTIONS));
    float qualityCount = clamp(floor(quality + 0.5), 1.0, float(MAX_QUALITY));
    float maxApply = 0.0;

    // Limites constantes: funcionan tanto en OpenGL/CNE como en drivers GLSL estrictos.
    for (int directionIndex = 0; directionIndex < MAX_DIRECTIONS; directionIndex++) {
        if (float(directionIndex) >= directionCount) break;
        float d = TWO_PI * float(directionIndex) / directionCount;

        for (int qualityIndex = 1; qualityIndex <= MAX_QUALITY; qualityIndex++) {
            if (float(qualityIndex) > qualityCount) break;
            float i = float(qualityIndex) / qualityCount;
            float x_movement = (sin(d) * size * i) / openfl_TextureSize.y;
            float y_movement = (cos(d) * size * i) / openfl_TextureSize.x;
            bloom += flixel_texture2D(bitmap, uv + vec2(x_movement, y_movement));
            bloom *= mix(1.0, 1.0 - (i / qualityCount), step(0.0, x_movement) + step(0.0, y_movement));

            maxApply += 1.0; // Increment by 1 for each direction
        }
    }

    float brightnessFactor = 1.0 - (1.0 / max(maxApply, 1.0));
    bloom /= max(maxApply, 1.0);

    float brightnessApply = brightness;
    if (brightness < 1.5)
        brightnessApply = mix(1.5, 0.0, abs(1.0 - ((brightness - 1.0) * 2.0)));

    gl_FragColor = color + ((bloom * brightnessFactor) * brightnessApply);
    // if (uv.x > 0.5) gl_FragColor = vec4(brightnessApply, brightnessApply, brightnessApply, 1.0);
}
