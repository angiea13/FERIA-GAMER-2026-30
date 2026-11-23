shader_type canvas_item;

varying vec4 mod_color;

void vertex() {
	mod_color = COLOR;   // aquí COLOR es el modulate del nodo
}

// 0 = limpio, 1 = máxima distorsión (lo controla el script)
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
// Cuánto se desplazan las franjas (en UV)
uniform float max_shift = 0.015;
uniform float bands = 40.0;
uniform float fps = 12.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float t = floor(TIME * fps);          // el glitch "salta" en pasos, no es fluido
	float band = floor(UV.y * bands);

	// A más intensidad, más franjas se descolocan
	float r = hash(vec2(band, t));
	float active = step(1.0 - intensity * 0.6, r);
	float shift = (hash(vec2(band + 7.0, t)) - 0.5) * 2.0 * max_shift * intensity * active;

	// Aberración cromática (canales RGB separados)
	float ca = max_shift * 0.5 * intensity;
	vec2 uv = vec2(UV.x + shift, UV.y);

	vec4 cr = texture(TEXTURE, uv + vec2(ca, 0.0));
	vec4 cg = texture(TEXTURE, uv);
	vec4 cb = texture(TEXTURE, uv - vec2(ca, 0.0));

	vec4 c = vec4(cr.r, cg.g, cb.b, max(cr.a, max(cg.a, cb.a)));

	// Parpadeos ocasionales cuando ya está muy distorsionado
	float flicker = step(0.96, hash(vec2(t, 3.0))) * intensity * 0.6;
	c.a *= 1.0 - flicker;

	COLOR = c * mod_color;
}