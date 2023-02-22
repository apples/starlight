shader_type canvas_item;
render_mode blend_mix,unshaded;

uniform sampler3D noise : source_color, filter_linear, repeat_enable;
uniform vec4 color : source_color;
uniform float speed = 1.0;

uniform float edge_thickness = 1.0;
uniform float edge_left;
uniform float edge_right;
uniform float edge_top;
uniform float edge_bottom;

varying float edge_left_dist;
varying float edge_right_dist;
varying float edge_top_dist;
varying float edge_bottom_dist;

void vertex() {
	edge_left_dist = (edge_left - VERTEX.x) / edge_thickness;
	edge_right_dist = (VERTEX.x - edge_right) / edge_thickness;
	edge_top_dist = (edge_top - VERTEX.y) / edge_thickness;
	edge_bottom_dist = (VERTEX.y - edge_bottom) / edge_thickness;
}

void fragment() {
	float alpha = 0.0;
	
	if (edge_left_dist >= 0.0 && edge_left_dist < 1.0) {
		float uvx = edge_left_dist / edge_thickness * (dFdx(UV.x) / dFdy(UV.y));
		alpha = texture(noise, vec3(uvx, UV.y, TIME * speed)).a;
	}
	
	if (edge_right_dist >= 0.0 && edge_right_dist < edge_thickness) {
		alpha = texture(noise, vec3(edge_right_dist, UV.y, TIME * speed)).a;
	}
	
	if (edge_top_dist >= 0.0 && edge_top_dist < edge_thickness && edge_top_dist > edge_left_dist && edge_top_dist > edge_right_dist) {
		alpha = texture(noise, vec3(UV.x, edge_top_dist, TIME * speed)).a;
	}
	
	if (edge_bottom_dist >= 0.0 && edge_bottom_dist < edge_thickness && edge_bottom_dist > edge_left_dist && edge_bottom_dist > edge_right_dist) {
		alpha = texture(noise, vec3(UV.x, edge_bottom_dist, TIME * speed)).a;
	}
	
	
	if (alpha < 0.5)
		discard;
	COLOR = color * vec4(1,1,1,alpha);
}
