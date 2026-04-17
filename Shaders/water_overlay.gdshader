shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float speed : hint_range(0.0, 2.0) = 0.4;
uniform float strength : hint_range(0.0, 0.1) = 0.016;
uniform float scale : hint_range(1.0, 20.0) = 4.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float time = TIME * speed;

	float wave1x = sin(uv.y * scale + time) * strength;
	float wave1y = cos(uv.x * scale + time * 0.7) * strength;

	float wave2x = sin(uv.y * scale * 2.3 + time * 1.3 + 1.5) * strength * 0.5;
	float wave2y = cos(uv.x * scale * 1.7 - time * 0.9 + 0.8) * strength * 0.5;

	uv.x += wave1x + wave2x;
	uv.y += wave1y + wave2y;

	vec4 screen = texture(SCREEN_TEXTURE, uv);
	screen.rgb *= vec3(0.8, 0.92, 1.08);

	COLOR = screen;
}