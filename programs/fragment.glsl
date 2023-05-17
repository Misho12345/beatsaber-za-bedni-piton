#version 450 core

layout (location = 0) out vec4 fragColor;

uniform float u_time;
uniform vec2 u_resolution;

uniform vec3 u_camPos;
uniform vec2 u_camRot;

uniform vec3 u_swordPos;
uniform vec3 u_swordRot;

#define MAX_MARCH_STEPS 200
#define MIN_DIST 0.01
#define MAX_DIST 100.0
#define FOV tan(radians(60.0))

#include common.glsl
#include scene.glsl
#include lighting.glsl

vec3 raymarch(vec3 rayOrigin, vec3 rayDir) {
    float dist = 0.0;
    float totalDist = 0.0;

    vec3 sky = vec3(0.53, 0.8, 0.92);

    for (int i = 0; i < MAX_MARCH_STEPS; i++) {
        Object scene = sceneSDF(rayOrigin + totalDist * rayDir, true);
        dist = scene.dist;
        totalDist += dist;
        if (dist < MIN_DIST) {
            vec3 pos = rayOrigin + totalDist * rayDir;
            vec3 col = getLight(pos, rayDir, scene.mat);
           	return col;
            return mix(col, sky, 1.0 - exp(-1e-7 * dist * dist * dist));
        }

        if (totalDist > MAX_DIST) {
            return sky;
        }
    }
}

mat3 getCam() {
    vec3 camF = vec3(
        cos(u_camRot.x) * cos(u_camRot.y),
        sin(u_camRot.y),
        sin(u_camRot.x) * cos(u_camRot.y)
    );

    vec3 camR = normalize(cross(vec3(0, 1, 0), camF));
    vec3 camU = cross(camF, camR);
    return mat3(camR, camU, camF);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy * 2.0 - 1.0;
    uv.x *= u_resolution.x / u_resolution.y;

    vec3 rayDir = getCam() * normalize(vec3(uv, FOV));
	vec3 rayOrigin = u_camPos;

	vec3 color = raymarch(rayOrigin, rayDir);
	fragColor = vec4(color, 1.0);
}