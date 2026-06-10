#pragma header

uniform float intensity = 10.0;

vec4 applyBlur(vec2 uv) {
    vec4 color = vec4(0.0);
    float total = 0.0;
    float radius = intensity;

    for (float x = -radius; x <= radius; x += 1.0) {
        for (float y = -radius; y <= radius; y += 1.0) {
            float weight = exp(-(x * x + y * y) / (2.0 * radius * radius));
            vec2 offset = vec2(x, y) / openfl_TextureSize;
            color += texture2D(bitmap, uv + offset) * weight;
            total += weight;
        }
    }

    return color / total;
}

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec4 originalColor = texture2D(bitmap, uv);

    if (uv.x >= 0.0 && uv.y >= 0.0 && uv.x <= 1.0 && uv.y <= 1.0) {
        gl_FragColor = applyBlur(uv);
    } else {
        gl_FragColor = originalColor;
    }
}