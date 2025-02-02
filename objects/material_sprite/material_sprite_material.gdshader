shader_type spatial;
render_mode unshaded,blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,shadows_disabled;
uniform float alpha_scissor_threshold : hint_range(0,1) = 0.5;
uniform vec4 albedo : source_color = vec4(1, 1, 1, 1);
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap_anisotropic,repeat_disable;
uniform vec3 uv1_scale = vec3(1, 1, 1);
uniform vec3 uv1_offset;

#include "texture2DAA.gdshaderinc"

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}

void fragment() {
	vec4 albedo_tex = texture2DAA(texture_albedo, UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ALPHA *= albedo.a * albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}
