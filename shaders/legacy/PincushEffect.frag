#pragma header
// made by leCharterfnf and took some code from a shader made by theZoroforce240, do NOT leak in any case

uniform float distort;

vec2 PincushionDistortion(in vec2 uv, float strength) {
	vec2 st = uv - 0.5;
	float uvA = atan(st.x, st.y);
	float uvD = dot(st, st);
	return 0.5 + vec2(sin(uvA), cos(uvA)) * sqrt(uvD) * (1.0 - strength * uvD);
}

void main() {
  vec2 uv = openfl_TextureCoordv.xy;
  uv = distort != 0.0 ? PincushionDistortion(uv, distort) : uv;
  if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {discard;}
  gl_FragColor = texture2D(bitmap, uv);
}