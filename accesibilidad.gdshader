shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

// 0 = normal, 1 = protanopía, 2 = deuteranopía, 3 = tritanopía
uniform int colorblind_mode = 0;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

uniform bool high_contrast = false;
uniform float contrast : hint_range(1.0, 3.0) = 1.8;
uniform float saturation : hint_range(0.0, 2.0) = 1.4;

vec3 simulate(vec3 c, int m) {
	if (m == 1) {
		return vec3(
			dot(c, vec3( 0.152286, 1.052583, -0.204868)),
			dot(c, vec3( 0.114503, 0.786281,  0.099216)),
			dot(c, vec3(-0.003882, -0.048116, 1.051998)));
	} else if (m == 2) {
		return vec3(
			dot(c, vec3( 0.367322, 0.860646, -0.227968)),
			dot(c, vec3( 0.280085, 0.672501,  0.047413)),
			dot(c, vec3(-0.011820, 0.042940,  0.968881)));
	}
	return vec3(
		dot(c, vec3( 1.255528, -0.076749, -0.178779)),
		dot(c, vec3(-0.078411,  0.930809,  0.147602)),
		dot(c, vec3( 0.004733,  0.691367,  0.303900)));
}

void fragment() {
	vec4 src = texture(screen_tex, SCREEN_UV);
	vec3 original = src.rgb;
	vec3 result = original;

	// 1) Corrección de daltonismo
	if (colorblind_mode >= 1) {
		vec3 lin = pow(original, vec3(2.2));
		vec3 err = lin - simulate(lin, colorblind_mode);
		vec3 corrected = lin;

		if (colorblind_mode == 3) {
			corrected.r += err.b * 0.7;
			corrected.g += err.b * 0.7;
		} else {
			corrected.g += err.r * 0.7 + err.g;
			corrected.b += err.r * 0.7 + err.b;
		}
		result = pow(clamp(corrected, 0.0, 1.0), vec3(1.0 / 2.2));
	}

	// Intensidad solo del filtro de daltonismo
	result = mix(original, result, intensity);

	// 2) Alto contraste (se aplica encima, se puede combinar)
	if (high_contrast) {
		float luma = dot(result, vec3(0.2126, 0.7152, 0.0722));
		vec3 sat = mix(vec3(luma), result, saturation);
		result = clamp((sat - 0.5) * contrast + 0.5, 0.0, 1.0);
	}

	COLOR = vec4(result, src.a);
}