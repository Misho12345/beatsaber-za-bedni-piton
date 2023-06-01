#version 450 core

layout (location = 0) out vec4 fragColor;

uniform float u_time;
uniform vec2 u_resolution;

uniform vec3 u_camPos;
uniform vec2 u_camRot;

uniform vec3 u_swordPos;
uniform vec3 u_swordDir;
bool swordVisible;

uniform sampler2D u_texture0;
uniform sampler2D u_texture1;

#define ENEMIES_COUNT 2
uniform vec3 u_enemiesPos[ENEMIES_COUNT];
bool enemiesVisible[ENEMIES_COUNT];

#define MAX_MARCH_STEPS 200.0
#define MAX_DIST 2500.0

#define MAX_SHADOW_MARCH_STEPS 60.0
#define MAX_SHADOW_DIST 500.0

#define MIN_DIST 0.01

#define FOV tan(radians(50.0))
#define EPS 0.001

#include common.glsl
#include terrain.glsl
#include scene.glsl
#include lighting.glsl

vec3 raymarch(in vec3 rayOrigin, in vec3 rayDir) {
    vec3 lightPos = normalize(vec3(-0.4, 1.1, 0.5));

    Object scene;
    float totalDist = 0.0;
    vec3 col, bgcol = dome(rayDir, lightPos);
    float sundotc = clamp01(dot(rayDir, lightPos));

    for (int i = 0; i < MAX_MARCH_STEPS; i++) {
        scene = sceneSDF(rayOrigin + totalDist * rayDir, true);
        totalDist += scene.dist;
        if (abs(scene.dist) < MIN_DIST || totalDist > MAX_DIST) break;
    }

    if (totalDist > MAX_DIST) {
        col = bgcol;

        col += vec3(0.24, 0.12, 0.24) * pow(sundotc, 5.0);
        col += vec3(0.24, 0.1, 0.24) * pow(sundotc, 64.0);
        col += vec3(0.48, 0.15, 0.24) * pow(sundotc, 512.0);

        // clouds
        vec2 sc = rayOrigin.xz + rayDir.xz * (1000.0 - rayOrigin.y) / rayDir.y;
        col = mix(col, 0.25 * vec3(0.5, 0.9, 1.0), 0.4 * texture(u_texture0, 5e-6 * sc).x);

        // sun scatter
        col += vec3(0.06, 0.035, 0.016) * pow(sundotc, 4.0);
    } else {
        vec3 pos = rayOrigin + totalDist * rayDir;
        col = getLight(pos, rayDir, scene.mat, lightPos);

        col = mix(col, 0.25 * mix(vec3(0.4, 0.75, 1.0), vec3(0.3, 0.3, 0.3), sundotc * sundotc), 1.0 - exp(-8e-7 * totalDist * totalDist));
        col += 0.15 * vec3(1.0, 0.8, 0.3) * pow(sundotc, 8.0) * (1.0 - exp(-0.003 * totalDist));
        col = mix(col, bgcol, 1.0 - exp(-4e-8 * totalDist * totalDist));
    }

    col = pow(col, vec3(0.45));

    // color grading
    col *= vec3(1.4, 1.4, 1.65);
    col = clamp(col, 0.0, 1.0);
    col *= col * (3.0 - 2.0 * col);
    col = mix(col, vec3(dot(col, vec3(0.333))), -0.2);

    return col;
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

    mat3 cam = getCam();
    vec3 rayDir = cam * normalize(vec3(uv, FOV));
	vec3 rayOrigin = u_camPos;

    for (int i = 0; i < ENEMIES_COUNT; i++) {
        vec3 pos = u_enemiesPos[i] + vec3(0, 2.0, 0.5);
        enemiesVisible[i] = intersectBox(rayOrigin, rayDir, pos, vec3(8, 13, 10));
    }

//    vec3 swordP = u_swordPos - u_swordDir * 0.1;
//    swordP.xz *= rotateMat(u_camRot.x);
//    swordP += u_camPos;
//
//    vec3 angles = dir2angles(u_swordDir);
//    angles.xz *= rotateMat(u_camRot.x);
////    swordVisible = intersectRotatedBox(rayOrigin, rayDir, swordP, vec3(2, 0.6, 0.6), angles);
//    swordVisible = intersectRotatedBox(rayOrigin, rayDir, swordP, vec3(0.6, 0.1, 0.1), angles + vec3(sin(u_camRot.x), 0, 0));

    swordVisible = true;

	vec3 color = raymarch(rayOrigin, rayDir);
	fragColor = vec4(color, 1.0);
}