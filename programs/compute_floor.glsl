#version 430 core

layout(std430, binding = 0) buffer InputBuffer  { vec2  inputBuffer[];  };
layout(std430, binding = 1) buffer HeightBuffer { float heightBuffer[]; };
layout(std430, binding = 2) buffer NormalBuffer { vec3  normalBuffer[]; };


layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

const mat2 m = mat2(1.6, -1.2, 1.2, 1.6);

float noi(in vec2 p) {
    p *= 6.2831;
    return 0.5 * (cos(p.x) + cos(p.y));
}

float terrainSDF(in vec2 p) {
    p *= 0.0013;
    float s = 1.0;
    float t = 0.0;

    for (int i = 0; i < 6; i++) {
        t += s * noi(p);
        s *= 0.5 + 0.1 * t;

        p = 0.97 * m * p + (t - 0.5) * 0.2;
    }

    return t;
}


vec3 normal() {
    vec3 p = vec3(inputBuffer[0].x, heightBuffer[0], inputBuffer[0].y);
   	vec2 e = vec2(0.01, 0.0);

    vec3 p1;
    p1.xz = p.xz - e.xy;
    p1.y = terrainSDF(p1.xz) * 55.0;

    vec3 p2;
    p2.xz = p.xz - e.yx;
    p2.y = terrainSDF(p2.xz) * 55.0;

    vec3 p3;
    p3.xz = p.xz + e.xy;
    p3.y = terrainSDF(p3.xz) * 55.0;

    vec3 p4;
    p4.xz = p.xz + e.yx;
    p4.y = terrainSDF(p4.xz) * 55.0;

    return normalize(cross(p3 - p1, p4 - p2));
}

void main() {
    heightBuffer[0] = terrainSDF(inputBuffer[0]) * 55.0;
    normalBuffer[0] = normal();
}