shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

instance uniform vec4 color : source_color = vec4(1, 1, 1, 1);
instance uniform float t0 = 0.0;
instance uniform float r = 0.0;
uniform vec4 modulate : source_color = vec4(1, 1, 1, 1);
uniform float speed = 1.0;
uniform float edge_power = 1.0;
uniform sampler3D noise_3d;

varying float edge;

void vertex() {
	edge = VERTEX_ID % 2 == 0 ? 1.0 : 0.0;
	UV = mat2(vec2(cos(r), sin(r)), vec2(-sin(r), cos(r))) * UV;
}

void fragment() {
	ALBEDO = color.rgb * modulate.rgb;
	ALPHA = clamp(color.a * modulate.a * pow(edge, edge_power) * texture(noise_3d, vec3(UV.x, UV.y, t0 + speed * TIME)).r, 0.0, 1.0);
}
