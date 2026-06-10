#pragma header

uniform float amplitude;
uniform float speed;
uniform float time;

void main() {
    vec2 uv = openfl_TextureCoordv;
    
    float shakeX = sin(time * speed * 10.0) * amplitude * 0.01;
    float shakeY = cos(time * speed * 8.0) * amplitude * 0.01;
    
    uv.x += shakeX;
    uv.y += shakeY;
    
    vec4 color = texture2D(bitmap, uv);
    gl_FragColor = color;
}