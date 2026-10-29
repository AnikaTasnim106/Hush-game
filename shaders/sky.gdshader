shader_type canvas_item;
// Dusk sky gradient with soft clouds and a low sun.
uniform float time = 0.0;
uniform float scroll = 0.0;
uniform vec3 top_col : source_color = vec3(0.16, 0.17, 0.36);
uniform vec3 mid_col : source_color = vec3(0.62, 0.38, 0.52);
uniform vec3 low_col : source_color = vec3(0.98, 0.66, 0.38);
uniform vec2 sun = vec2(0.72, 0.68);

float hash(vec2 p){ return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453); }
float noise(vec2 p){
	vec2 i = floor(p), f = fract(p);
	float a = hash(i), b = hash(i + vec2(1,0)), c = hash(i + vec2(0,1)), d = hash(i + vec2(1,1));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}
float fbm(vec2 p){ float v = 0.0; float a = 0.5; for (int i=0;i<4;i++){ v += a*noise(p); p *= 2.03; a *= 0.5;} return v; }

void fragment() {
	vec2 uv = UV;
	vec3 col = mix(top_col, mid_col, smoothstep(0.0, 0.62, uv.y));
	col = mix(col, low_col, smoothstep(0.55, 0.95, uv.y));
	vec2 sp = uv - sun; sp.x *= 1.78;
	float sd = length(sp);
	col += vec3(1.0, 0.8, 0.5) * exp(-sd * 9.0) * 0.6;
	col = mix(col, vec3(1.0, 0.92, 0.75), smoothstep(0.055, 0.045, sd));
	float cl = fbm(vec2(uv.x * 3.0 + scroll * 0.02 + time * 0.004, uv.y * 7.0));
	float band = smoothstep(0.25, 0.55, uv.y) * smoothstep(0.85, 0.5, uv.y);
	col = mix(col, mix(vec3(0.98, 0.72, 0.62), vec3(0.45, 0.33, 0.5), uv.y), smoothstep(0.55, 0.8, cl) * band * 0.55);
	COLOR = vec4(col, 1.0);
}
