shader_type spatial;
render_mode cull_disabled, blend_add, unshaded;

uniform vec4 color : source_color = vec4(0.95, 0.95, 1.0, 0.45);

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
}