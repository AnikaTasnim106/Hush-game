shader_type canvas_item;
// The Hush drains colour from the world. Restored circles bring it back.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform vec4 circles[16];      // xy = centre (screen px), z = radius px, w = ring glow 0..1
uniform int count = 0;
uniform vec2 vsize = vec2(1280.0, 720.0);
uniform float base_sat = 0.12;
uniform float global_colour = 0.0;
uniform float time = 0.0;
uniform vec4 lights[16];       // xy = centre (screen px), z = radius px, w = strength
uniform int light_count = 0;
uniform float darkness = 0.0;  // 0 = none, 1 = pitch dark outside lights

float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	vec2 p = SCREEN_UV * vsize;
	float m = global_colour;
	float ring = 0.0;
	for (int i = 0; i < 16; i++) {
		if (i >= count) break;
		vec4 ci = circles[i];
		vec2 d = p - ci.xy;
		float ang = atan(d.y, d.x);
		float wob = sin(ang * 7.0 + time * 1.3 + float(i)) * 10.0 + sin(ang * 13.0 - time * 2.0) * 5.0;
		float dist = length(d) + wob;
		m = max(m, 1.0 - smoothstep(ci.z - 40.0, ci.z, dist));
		ring += ci.w * exp(-abs(dist - ci.z) / 14.0);
	}
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 grey = vec3(g * 0.93, g * 0.97, g * 1.07);      // cool, silenced
	grey = mix(grey, vec3(0.46, 0.48, 0.53), 0.16);       // flatter contrast
	vec3 drained = mix(grey, c, base_sat);
	vec3 vivid = clamp(mix(vec3(g), c, 1.15), 0.0, 1.0);  // a touch richer than normal
	vec3 outc = mix(drained, vivid, m);
	outc += vec3(1.0, 0.85, 0.5) * clamp(ring, 0.0, 1.0) * 0.55;
	if (darkness > 0.001) {
		float lit = 0.0;
		vec3 warm = vec3(0.0);
		for (int i = 0; i < 16; i++) {
			if (i >= light_count) break;
			vec4 li = lights[i];
			float dd = length(p - li.xy) / max(li.z, 1.0);
			float k = li.w * clamp(1.0 - dd * dd, 0.0, 1.0);
			lit += k;
			warm += vec3(1.0, 0.82, 0.55) * k * 0.08;
		}
		lit = clamp(lit, 0.0, 1.0);
		vec3 night = outc * vec3(0.42, 0.5, 0.72);           // moonlit blue
		float amb = 1.0 - darkness;
		outc = mix(night * amb + outc * 0.0, outc, max(lit, amb)) + warm * darkness;
	}
	COLOR = vec4(outc, 1.0);
}
