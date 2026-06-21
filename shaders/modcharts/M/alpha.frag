#pragma header

uniform float strength;
uniform float intensity;

const float EDGE_THRESHOLD = 0.05;
const float EDGE_SOFTNESS = 0.15;
const float EDGE_ALPHA_AT_CENTER = 1.0;
const float EDGE_ALPHA_AT_BORDER = 0.7;
const float EDGE_KEEP = 0.35;

float luminance(vec4 color)
{
	return dot(color.rgb, vec3(0.299, 0.587, 0.114)) * color.a;
}

void main()
{
	vec2 uv = openfl_TextureCoordv;
	vec4 col = flixel_texture2D(bitmap, uv);

	if (strength <= 0.0)
	{
		gl_FragColor = col;
		return;
	}

	vec2 pixel = (1.0 / openfl_TextureSize.xy) * max(intensity, 0.001);

	float topLeft = luminance(flixel_texture2D(bitmap, uv + vec2(-pixel.x, -pixel.y)));
	float topMiddle = luminance(flixel_texture2D(bitmap, uv + vec2(0.0, -pixel.y)));
	float topRight = luminance(flixel_texture2D(bitmap, uv + vec2(pixel.x, -pixel.y)));

	float midLeft = luminance(flixel_texture2D(bitmap, uv + vec2(-pixel.x, 0.0)));
	float midRight = luminance(flixel_texture2D(bitmap, uv + vec2(pixel.x, 0.0)));

	float bottomLeft = luminance(flixel_texture2D(bitmap, uv + vec2(-pixel.x, pixel.y)));
	float bottomMiddle = luminance(flixel_texture2D(bitmap, uv + vec2(0.0, pixel.y)));
	float bottomRight = luminance(flixel_texture2D(bitmap, uv + vec2(pixel.x, pixel.y)));

	float gx = topLeft + (2.0 * midLeft) + bottomLeft - topRight - (2.0 * midRight) - bottomRight;
	float gy = topLeft + (2.0 * topMiddle) + topRight - bottomLeft - (2.0 * bottomMiddle) - bottomRight;
	float edge = sqrt((gx * gx) + (gy * gy));
	edge = smoothstep(EDGE_THRESHOLD, EDGE_THRESHOLD + EDGE_SOFTNESS, edge);

	vec2 centered = uv - vec2(0.5);
	centered.x *= openfl_TextureSize.x / openfl_TextureSize.y;
	float dist = clamp(length(centered) * 2.0, 0.0, 1.0);
	float radialStrength = mix(EDGE_ALPHA_AT_CENTER, EDGE_ALPHA_AT_BORDER, smoothstep(0.0, 1.0, dist));

	float alphaCut = radialStrength * clamp(strength, 0.0, 1.0);
	float fillAlpha = col.a * (1.0 - alphaCut);
	float edgeAlpha = col.a * EDGE_KEEP;
	float finalAlpha = mix(fillAlpha, max(fillAlpha, edgeAlpha), edge);

	gl_FragColor = vec4(col.rgb, finalAlpha);
}
