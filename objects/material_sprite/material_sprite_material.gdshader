shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,unshaded,alpha_to_coverage;
uniform bool sprite_filter_trilinear;
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

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}

vec4 textureDownsampleBilinear(sampler2D tex, vec2 uv) {
	vec2 texsize = vec2(textureSize(tex,0));
	vec2 uv_texspace = uv*texsize;
	vec2 uv_texspace_root = floor((uv_texspace - 1.0) * 0.5) * 2.0 + 1.0;
	vec2 uv_root = uv_texspace_root / texsize;
	vec2 uv_next = (uv_texspace_root + 2.0) / texsize;
	
	vec4 sample_ul = texture(tex, vec2(uv_root.x, uv_root.y));
	vec4 sample_ur = texture(tex, vec2(uv_next.x, uv_root.y));
	vec4 sample_bl = texture(tex, vec2(uv_root.x, uv_next.y));
	vec4 sample_br = texture(tex, vec2(uv_next.x, uv_next.y));
	
	vec2 weight = (uv_texspace - uv_texspace_root) / 2.0;
	
	vec4 top = sample_ul * (1.0 - weight.x) + sample_ur * weight.x;
	vec4 bottom = sample_bl * (1.0 - weight.x) + sample_br * weight.x;
	
	vec4 final = top * (1.0 - weight.y) + bottom * weight.y;
	
	return final;
}

vec4 textureTrilinear(sampler2D tex, vec2 uv) {
	vec4 mip0 = texture(tex, uv);
	vec4 mip1 = textureDownsampleBilinear(tex, uv);
	
	vec2 texsize = vec2(textureSize(tex,0));
	vec2 uv_texspace = uv*texsize;
	vec2 deriv = fwidth(uv_texspace);
	
	float z = clamp(length(deriv) * 0.707 - 1.0, 0.0, 1.0);
	
	return mip0 * (1.0 - z) + mip1 * z;
}

vec4 texture2DAA(sampler2D tex, vec2 uv) {
	vec2 texsize = vec2(textureSize(tex,0));
	vec2 uv_texspace = uv*texsize;
	vec2 deriv = fwidth(uv_texspace);
	
	if (length(deriv) > 1.414) {
		if (sprite_filter_trilinear) {
			return textureTrilinear(tex, uv);
		} else {
			return texture(tex, uv);
		}
	}
	
	vec2 seam = floor(uv_texspace+.5);
	uv_texspace = (uv_texspace-seam)/deriv+seam;
	uv_texspace = clamp(uv_texspace, seam-.5, seam+.5);
	return texture(tex, uv_texspace/texsize);
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
