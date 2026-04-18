shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float clarity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = uv - 0.5;
	float dist = length(center);

	float vignette = smoothstep(0.15 - clarity * 0.15, 0.6 - clarity * 0.2, dist);

	vec4 screen = texture(SCREEN_TEXTURE, uv);
	vec4 must_color = vec4(0.35, 0.28, 0.05, 1.0);

	float opacity = vignette * (1.0 - clarity) * 1.3;
	COLOR = mix(screen, must_color, clamp(opacity, 0.0, 1.0));
}