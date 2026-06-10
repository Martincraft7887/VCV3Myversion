#pragma header
uniform float iTime;
uniform float decay;
uniform float density;
uniform float weigth;
//modified from https://www.shadertoy.com/view/ls2Xzd
// Algorithm found in https://medium.com/community-play-3d/god-rays-whats-that-5a67f26aeac2
vec4 crepuscular_rays(vec2 texCoords, vec2 pos) {
    float decay = decay;
    float density = density;
    float weight = weigth;

    /// NUM_SAMPLES will describe the rays quality, you can play with
    const int nsamples = 50;

    vec2 tc = openfl_TextureCoordv.xy;
    vec2 deltaTexCoord = tc - pos.xy;
    deltaTexCoord *= (1.0 / float(nsamples) * density);
    float illuminationDecay = 1.0;

    vec4 color = flixel_texture2D(bitmap, tc.xy) * vec4(0.4);
	
    tc += deltaTexCoord * fract( sin(dot(texCoords.xy+fract(iTime), vec2(12.9898, 78.233)))* 43758.5453 );
    for (int i = 0; i < nsamples; i++)
	{
        tc -= deltaTexCoord;
        vec4 sampl = flixel_texture2D(bitmap, tc.xy) * vec4(0.4);

        sampl *= illuminationDecay * weight;
        color += sampl;
        illuminationDecay *= decay;
    }
    
    return color;
}

void main(){
    vec2 uv = openfl_TextureCoordv.xy;
	uv.x *= openfl_TextureCoordv.x / openfl_TextureCoordv.y; //fix aspect ratio
    vec3 pos = vec3(openfl_TextureCoordv.xy,0);
	pos.x *= openfl_TextureCoordv.x / openfl_TextureCoordv.y; //fix aspect ratio

		pos.x=sin(iTime)*.5;
		pos.y=sin(iTime*.913)*.5;
	
	gl_FragColor = crepuscular_rays (uv, pos.xy);
}