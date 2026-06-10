#pragma header

uniform float tx, ty;
uniform float uTime;
uniform float uSpeed;
uniform float uFrequency;
uniform float uWaveAmplitude;

vec2 sineWave(vec2 pt)
{
    float x = 0.0;
    float y = 0.0;
    
    float offsetY = sin(pt.x * uFrequency - uTime * uSpeed) * (uWaveAmplitude / pt.y * pt.x);
    float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * (uWaveAmplitude);
    pt.x += offsetX * (pt.y / 2.0);
    pt.y += offsetY * (pt.x / 2.0);

    return vec2(pt.x + x, pt.y + y);
}

void main(void)
{
    vec2 uv = sineWave(openfl_TextureCoordv);
    gl_FragColor = texture2D(bitmap, uv);
}