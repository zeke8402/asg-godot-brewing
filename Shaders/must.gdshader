shader_type spatial;
render_mode cull_disabled;

uniform float speed : hint_range(0.0, 2.0) = 0.3;
uniform float wave_strength : hint_range(0.0, 1.0) = 0.08;
uniform float tiling : hint_range(1.0, 20.0) = 6.0;
uniform vec4 shallow_color : source_color = vec4(0.18, 0.62, 0.75, 0.85);
uniform vec4 deep_color : source_color = vec4(0.05, 0.25, 0.45, 0.95);

void fragment() {
	vec2 uv = UV * tiling;
	float time = TIME * speed;
	
	float wave1 = sin(uv.x * 2.0 + time) * cos(uv.y * 1.5 + time * 0.8);
	float wave2 = sin(uv.x * 3.5 - time * 1.2) * cos(uv.y * 2.5 + time * 0.5);
	float wave3 = sin((uv.x + uv.y) * 2.0 + time * 0.7);
	
	float wave = (wave1 + wave2 + wave3) / 3.0;
	
	vec4 color = mix(shallow_color, deep_color, wave * 0.5 + 0.5);
	
	ALBEDO = color.rgb;
	ALPHA = color.a;
	METALLIC = 0.3;
	ROUGHNESS = 0.1;
	SPECULAR = 0.8;
}