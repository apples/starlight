shader_type canvas_item;
render_mode blend_mix,unshaded;

#include "texture2DAA.gdshaderinc"

void fragment() {
	COLOR = texture2DAA2(TEXTURE, UV);
	COLOR.a = round(COLOR.a);
}
