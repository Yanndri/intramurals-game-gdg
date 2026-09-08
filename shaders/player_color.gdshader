shader_type canvas_item;

uniform vec4 player_color : source_color = vec4(0.2, 0.65, 1.0, 1.0);
uniform float color_strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 sprite_color = texture(TEXTURE, UV);
	float luminance = dot(sprite_color.rgb, vec3(0.299, 0.587, 0.114));

	// Use the selected color as the actual base color while retaining the
	// original sprite's light and shadow detail.
	vec3 recolored_rgb = player_color.rgb * luminance * 1.8;
	float highlight = smoothstep(0.72, 1.0, luminance) * 0.35;
	recolored_rgb = mix(recolored_rgb, vec3(1.0), highlight);

	COLOR = vec4(mix(sprite_color.rgb, recolored_rgb, color_strength), sprite_color.a);
}
