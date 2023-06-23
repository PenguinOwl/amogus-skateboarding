shader_type spatial;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture;
uniform float SCAN_RADIUS = 3.0;

float vec4_avg(vec4 color) {
	return (color.r + color.g + color.b) / 3.0;
} 

float sigmoid (float x) {
    return 1.0 / (1.0 + (exp(-(x - 0.5) * 14.0))); 
}

void vertex() {
  POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	float depth = texture(depth_texture, SCREEN_UV).x;
	float sum = 0.0;
	for (float i = -SCAN_RADIUS; i <= SCAN_RADIUS; i++) {
		vec4 center = color;
		vec4 left = (texture(depth_texture, SCREEN_UV + vec2(-SCAN_RADIUS,i) * VIEWPORT_SIZE) + color) * vec4(0.5);
		vec4 right = (texture(depth_texture, SCREEN_UV + vec2(SCAN_RADIUS,i) * VIEWPORT_SIZE) + color) * vec4(0.5);
		vec4 upper = (texture(depth_texture, SCREEN_UV + vec2(i,-SCAN_RADIUS) * VIEWPORT_SIZE) + color) * vec4(0.5);
		vec4 lower = (texture(depth_texture, SCREEN_UV + vec2(i,SCAN_RADIUS) * VIEWPORT_SIZE) + color) * vec4(0.5);
		sum += abs(vec4_avg(left) - vec4_avg(center));
		sum += abs(vec4_avg(center) - vec4_avg(lower));
		sum += abs(vec4_avg(center) - vec4_avg(right));
		sum += abs(vec4_avg(upper) - vec4_avg(center));
	}
	sum /= (SCAN_RADIUS);
	sum *= 1.5;
	sum = sigmoid(sum);
	sum *= sum;
	ALBEDO = sum * vec3(1.0, 1.0, 0.4);
	ALBEDO = vec3(1.0, 1.0, 0.4);
}