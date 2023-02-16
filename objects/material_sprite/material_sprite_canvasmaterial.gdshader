shader_type canvas_item;
render_mode blend_mix,unshaded;

uniform bool sprite_filter_trilinear;

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
	COLOR = texture2DAA(TEXTURE, UV);
}
