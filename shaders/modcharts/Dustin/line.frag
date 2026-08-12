#pragma header

// El original era un prototipo incompleto: declaraba un array sin tamano,
// usaba "function main" y asignaba un vec2 a gl_FragColor. Esta version
// conserva la idea de dibujar una linea, pero usa parametros editables.
uniform float lineY;
uniform float thickness;
uniform float strength;

void main() {
	vec2 uv = openfl_TextureCoordv.xy;
	vec4 color = flixel_texture2D(bitmap, uv);
	float safeThickness = max(thickness, 0.00001);
	float lineMask = 1.0 - smoothstep(safeThickness, safeThickness * 2.0, abs(uv.y - lineY));
	vec3 lineColor = vec3(0.0, color.a, 0.0);

	gl_FragColor = vec4(mix(color.rgb, lineColor, lineMask * clamp(strength, 0.0, 1.0)), color.a);
}
