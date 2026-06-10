#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
#define texture flixel_texture2D

void mainImage( out vec4 f, vec2 w ){
    vec4 p = vec4(w,0.,1.)/iResolution.xyxx*6.-3.,z = p-p, c, d=z;
    float t = iTime;
    p.x -= t * .4;

    for(float i=0.; i<8.; i+=.3) {
        c = texture(iChannel0, p.xy * .0029) * 11.;
        d.x = cos(c.x + t);
        d.y = sin(c.y + t);
        z += (2. - abs(p.y)) * vec4(.1 * i, .3, .2, 9);
        z *= dot(d, d - d + .03) + .98;
        p -= d * .022;
    }

    
    vec4 effectColor = z / 12.;

  
    vec4 originalColor = texture(iChannel0, w / iResolution.xy);

    
    f = mix(originalColor, effectColor, 0.5);
}

void main() {
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}