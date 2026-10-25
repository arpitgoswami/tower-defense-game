shader_type canvas_item;
// White hit-flash. flash = 0 (normal) .. 1 (fully white), alpha is preserved.
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.rgb = mix(c.rgb, vec3(1.0), flash);
	COLOR = c * COLOR;
}
