shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float SCAN_RADIUS = 3.0;
uniform float strength = 0.0;

float vec4_avg(vec4 color) {
	return (color.r + color.g + color.b) / 3.0;
} 

float sigmoid (float x) {
    return 1.0 / (1.0 + (exp(-(x - 0.5) * 14.0))); 
}

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	float sum = 0.0;
	for (float i = -SCAN_RADIUS; i <= SCAN_RADIUS; i++) {
		vec4 center = color;
		vec4 left = (texture(screen_texture, SCREEN_UV + vec2(-SCAN_RADIUS,i) * SCREEN_PIXEL_SIZE) + color) * vec4(0.5);
		vec4 right = (texture(screen_texture, SCREEN_UV + vec2(SCAN_RADIUS,i) * SCREEN_PIXEL_SIZE) + color) * vec4(0.5);
		vec4 upper = (texture(screen_texture, SCREEN_UV + vec2(i,-SCAN_RADIUS) * SCREEN_PIXEL_SIZE) + color) * vec4(0.5);
		vec4 lower = (texture(screen_texture, SCREEN_UV + vec2(i,SCAN_RADIUS) * SCREEN_PIXEL_SIZE) + color) * vec4(0.5);
		sum += abs(vec4_avg(left) - vec4_avg(center));
		sum += abs(vec4_avg(center) - vec4_avg(lower));
		sum += abs(vec4_avg(center) - vec4_avg(right));
		sum += abs(vec4_avg(upper) - vec4_avg(center));
	}
	sum /= (SCAN_RADIUS);
	sum *= 2.0;
	sum = sigmoid(sum);
	sum *= sum;
	COLOR = strength * (sum * vec4(1.0, 1.0, 0.4, 1.0) + (1.0 - sum) * vec4(0,0,0,1.0)) + (1.0-strength) * color;
}
