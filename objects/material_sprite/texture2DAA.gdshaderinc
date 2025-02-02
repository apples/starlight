
vec4 texture2DAA(sampler2D tex, vec2 uv) {
	float lod = textureQueryLod(tex, uv).x;
	
	if (uv.x < 0.1 && uv.y < 0.1) {
		float mip = floor(lod + 0.499);
		if (mip == 0.0) {
			return vec4(0, 0, 0, 1);
		} else if (mip == 1.0) {
			return vec4(1, 0, 0, 1);
		} else if (mip == 2.0) {
			return vec4(0, 1, 0, 1);
		} else {
			return vec4(1, 1, 1, 1);
		}
	}
	
	vec2 texture_pixel_size = 1.0 / vec2(textureSize(tex, 0));
	
	if (length(uv - vec2(textureSize(tex, int(lod))) / vec2(240.0, 336.0)) < 0.05) {
		return vec4(1, 0, 1, 1);
	}
	
	vec2 uv_per_pixel = fwidth(uv);
	
	float scale_ratio = length(texture_pixel_size) / length(uv_per_pixel);
	
	if (scale_ratio < 1.0) {
		if (uv.x > 0.9 && uv.y < 0.1) {
			return vec4(0, 0, 1, 1);
		}
		return textureLod(tex, uv, lod);
	}
	
	vec2 nearest_texel_corner = round(uv / texture_pixel_size);
	vec2 nearest_texel_corner_uv = nearest_texel_corner * texture_pixel_size;
	
	vec2 uv_dist_to_nearest = uv - nearest_texel_corner_uv;
	vec2 pixel_dist_to_nearest = uv_dist_to_nearest / uv_per_pixel;
	
	vec2 bilinear_filter_value = clamp(pixel_dist_to_nearest, -0.5, 0.5);
	
	vec2 sharp_uv = (nearest_texel_corner + bilinear_filter_value) * texture_pixel_size;
	
	return textureLod(tex, sharp_uv, 0);
}