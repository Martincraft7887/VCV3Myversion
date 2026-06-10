#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
uniform float uTime;
uniform float money;
uniform float colorraro;
uniform float strength; 

// Shared star settings
uniform float size;
uniform float core_size;
uniform float size_spike_vertical;
uniform float size_spike_horizontal;
uniform float star_brightness; // Base brightness

// Star 1 position
uniform float star_position_x_1;
uniform float star_position_y_1;

// Star 2 position
uniform float star_position_x_2;
uniform float star_position_y_2;

#define iChannel0 bitmap
#define texture flixel_texture2D

vec2 FragCoord;

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 get_star_color() {
    vec3 baseColor = vec3(0.9373, 0.3098, 0.0627); // Default pinkish color
    vec3 hsvColor = rgb2hsv(baseColor);
    
    if (money >= 1.1) {
        hsvColor.x += mod(uTime * 0.1, 1.0);
    } else {
        float hueIncrement = money;
        hsvColor.x = mod(hsvColor.x + mod(money, 1.0) * hueIncrement, 1.0);
    }

    // Handle color rarity adjustments
    if (colorraro == 0.0) {
        hsvColor.x = hsvColor.x;
    } else if (colorraro >= 1.1) {
        hsvColor.x = mod(uTime * 0.1, 1.0); // Another disco effect
    } else {
        hsvColor.x = mod(colorraro, 1.0);
    }

    // Darken the color for the "money effect" and enhance the saturation
    hsvColor.y = mix(hsvColor.y, 0.8, money * 0.3);  // Increase saturation based on money
    hsvColor.z = mix(hsvColor.z, 0.5, money * 0.3);  // Decrease brightness to make it darker

    return hsv2rgb(hsvColor);  // Convert back to RGB
}

// Function to draw a star with pulsating brightness and gradient effect
vec3 draw_star(vec2 pos, vec3 star_col, float size, float core_size, float spike_vertical, float spike_horizontal, float base_brightness) {
    pos -= FragCoord.xy / iResolution.xy;
    vec3 col = vec3(0.0);
    float d;

    // Pulsating brightness effect (reduced amplitude)
    float pulsation = 0.8 + 0.2 * sin(uTime * 2.0); // Reduced pulsation amplitude
    float brightness = base_brightness * pulsation * strength; // Appliquer le strength ici

    // Adjusted sizes
    float adjusted_size = 3.0 / (size + 0.1);
    float adjusted_core_size = 5.0 / (core_size + 0.1);

    // Distance from center
    float dist = length(pos);
    
    // Gradient effect: transition from white to star color
    float gradient = smoothstep(0.0, 0.8, dist * adjusted_core_size);
    vec3 coreColor = mix(star_col, vec3(1.0), gradient);  

    // Bright Core (White fading into the selected color)
    d = dist * adjusted_core_size;
    col += coreColor * brightness / (0.01 + d * d);

    // Colored glow around core
    col += star_col * brightness / (0.2 + d * d * 0.5);

    // Vertical spikes
    float adjusted_spike_vertical = 10.0 * spike_vertical;
    d = length(pos * vec2(1.0, 1.0 / adjusted_spike_vertical)) * adjusted_size;
    col += mix(vec3(1.0), star_col, smoothstep(0.1, 0.5, d)) * brightness / (0.01 + d * d);

    // Horizontal spikes
    float adjusted_spike_horizontal = 10.0 * spike_horizontal;
    d = length(pos * vec2(1.0 / adjusted_spike_horizontal, 1.0)) * adjusted_size;
    col += mix(vec3(1.0), star_col, smoothstep(0.1, 0.5, d)) * brightness / (0.01 + d * d);

    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 col;
    FragCoord = fragCoord;

    // Background (bitmap)
    vec3 backgroundColor = texture(iChannel0, fragCoord / iResolution.xy).rgb;

    // Compute star color dynamically
    vec3 star_color = get_star_color();

    // First star
    col = draw_star(vec2(1, 1), star_color, size, 0.7, 1.5, 1.85, 1);

    // Second star
    col += draw_star(vec2(0, 1), star_color, size, 0.7, 1.5, 1.85, 1);

    // Blend with background
    col = mix(backgroundColor, col, 0.05);

    // Final output
    fragColor = vec4(col, texture(iChannel0, fragCoord / iResolution.xy).a);
}

void main() {
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}