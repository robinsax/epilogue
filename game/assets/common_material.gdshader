shader_type spatial;
render_mode cull_disabled, // TODO: Lazy, there are flipped normals.
    specular_schlick_ggx,
    depth_draw_opaque,
    diffuse_burley;

#include "res://meta/util.gdshaderinc"
#include "res://assets/lighting.gdshaderinc"

uniform sampler2D tex;
uniform float metallic;
uniform float specular;
uniform float roughness;
uniform float brightness_correct;
uniform float thermal_emit;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = texture(tex, downsample_point(UV, 32.0) + vec2(1.0 / 32.0)).rgb - vec3(brightness_correct);
	EMISSION = vec3(0.0);

	if (view_modifier == 1) {
		ALBEDO = vec3(max(ALBEDO.r, max(ALBEDO.b, ALBEDO.g))) + vec3(1.0) + thermal_emit;
		EMISSION = vec3(thermal_emit * 10.0);
	}

	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}
