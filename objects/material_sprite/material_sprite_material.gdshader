shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,unshaded,alpha_to_coverage;
uniform float alpha_scissor_threshold : hint_range(0,1);
uniform float alpha_antialiasing_edge : hint_range(0,1);
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear,repeat_disable;
uniform ivec2 albedo_texture_size;
uniform float metallic;
uniform sampler2D texture_metallic : hint_default_white,filter_linear,repeat_disable;
uniform vec4 metallic_texture_channel;
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_roughness : hint_roughness_r,filter_linear,repeat_disable;
uniform float specular;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

#include "texture2DAA.gdshaderinc"

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture2DAA(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
	ALPHA *= albedo.a * albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
	ALPHA_ANTIALIASING_EDGE = alpha_antialiasing_edge;
	ALPHA_TEXTURE_COORDINATE = UV * vec2(textureSize(texture_albedo,0));
}
