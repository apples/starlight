
uniform bool sprite_filter_trilinear = true;
uniform float texture2DAA_bias : hint_range(0.0, 1.0, 0.1) = 1.0;

vec4 texture2DAA_textureDownsampleBilinear(sampler2D tex, vec2 uv) {
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

vec4 texture2DAA_textureTrilinear(sampler2D tex, vec2 uv) {
	vec4 mip0 = texture(tex, uv);
	vec4 mip1 = texture2DAA_textureDownsampleBilinear(tex, uv);
	
	vec2 texsize = vec2(textureSize(tex,0));
	vec2 uv_texspace = uv*texsize;
	vec2 deriv = fwidth(uv_texspace);
	
	float z = clamp(length(deriv) * 0.707 - 1.0, 0.0, 1.0);
	
	return mip0 * (1.0 - z) + mip1 * z;
}

vec4 texture2DAA(sampler2D tex, vec2 uv) {
	vec2 texsize = vec2(textureSize(tex,0));
	vec2 uv_texspace = uv*texsize;
	vec2 deriv = fwidth(uv_texspace) * texture2DAA_bias;
	
	if (length(fwidth(uv_texspace)) > 1.414) {
		if (sprite_filter_trilinear) {
			return texture2DAA_textureDownsampleBilinear(tex, uv);
		} else {
			return texture(tex, uv);
		}
	}
	
	vec2 seam = floor(uv_texspace+.5);
	uv_texspace = (uv_texspace-seam)/deriv+seam;
	uv_texspace = clamp(uv_texspace, seam-.5, seam+.5);
	return texture(tex, uv_texspace/texsize);
}

vec4 texture2DAA2(sampler2D tex, vec2 uv) {
	vec2 texSize = vec2(textureSize(tex, 0));
	vec2 boxSize = clamp(fwidth(uv) * texSize, 1e-5, 1.0);
	vec2 tx = uv * texSize - 0.5 * boxSize;
	vec2 txOffset = smoothstep(1.0 - boxSize, vec2(1.0), fract(tx));//clamp((fract(tx) - (1.0 - boxSize)) / boxSize, 0.0, 1.0);
	vec2 uvFinal = (floor(tx) + 0.5 + txOffset) / texSize;
	return textureGrad(tex, uvFinal, dFdx(uv), dFdy(uv));
}
