shader_type canvas_item;

uniform float opacity: hint_range(0.0, 1.0) = 1.0;
uniform float r: hint_range(0.0, 1.0) = 0.0;
uniform float g: hint_range(0.0, 1.0) = 0.0;
uniform float b: hint_range(0.0, 1.0) = 0.0;
uniform float mix_color: hint_range(0.0, 1.0) = 0.0;

void vertex() {
}

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	COLOR = vec4(
		mix(texture_color.rgb, vec3(r, g, b), mix_color),
		texture_color.a * opacity
	);
}

void light() {
	float cNdotL = max(1.0, dot(NORMAL, LIGHT_DIRECTION));
	LIGHT = vec4(LIGHT_COLOR.rgb * COLOR.rgb * LIGHT_ENERGY * cNdotL, LIGHT_COLOR.a);
}