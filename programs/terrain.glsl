const mat2 m = mat2(1.6, -1.2, 1.2, 1.6);

float noi(in vec2 p) {
    p *= 6.2831;
    return 0.5 * (cos(p.x) + cos(p.y));
}

float terrainSDF(in vec2 p, int iterations) {
    p *= 0.0013;
    float s = 1.0;
    float t = 0.0;

    for (int i = 0; i < iterations; i++) {
        t += s * noi(p);
        s *= 0.5 + 0.1 * t;

        p = 0.97 * m * p + (t - 0.5) * 0.2;
    }
    return t;
}


float terrainMed(in vec3 p) {
    float t = terrainSDF(p.xz, 6);
    float dist = length(p - u_camPos);
    if (dist < 200.0) {
        float rockT = texture(u_texture0, 0.03 * p.xz).x;
        float grassT = texture(u_texture1, 0.03 * p.xz).x;

        t -= mix(rockT, grassT, t / 95.0) * (1.0 - dist / 200.0) / 500.0;
    }
    return t * 55.0;
}

float terrainHigh(in vec3 p) {
    float t = terrainSDF(p.xz, 6);
    float dist = length(p - u_camPos);
    if (dist < 200.0) {
        float rockT = texture(u_texture0, 0.03 * p.xz).x;
        float grassT = texture(u_texture1, 0.03 * p.xz).x;

        t -= mix(rockT, grassT, t / 95.0) * (1.0 - dist / 200.0) / 25.0;
    }
    return t * 55.0;
}

vec2 map(in vec3 pos) {
    float h = pos.y - terrainMed(pos);

    float w = 0.5 + h / 100;
    return vec2(h * 0.5, clamp01(w * w));
}

float mapH(in vec3 pos) {
    float h = pos.y - terrainHigh(pos);
    return h * 0.5;
}

Material getMaterial(in vec3 pos, in vec2 res) {
    float dist = length(pos - u_camPos) / 200.0;
    float fdist = floor(dist);
    float k = smoothstep(fdist, ceil(dist), dist);

    // rock
    vec3 col = vec3(0.15, 0.12, 0.1);
    col *= 0.2 + mix(
        textureLod(u_texture0, 3e-4 * pos.xy / (fdist + 1), fdist).x,
        textureLod(u_texture0, 3e-4 * pos.xy / (fdist + 2), fdist + 1).x, k);

    vec3 col2 = vec3(0.15, 0.1, 0.05);
    col = mix(col, col2, 0.5 * res.y);

    // grass
    float s = smoothstep(0.05, 0.15, mix(
        textureLod(u_texture0, 1e-4 * pos.zx / (fdist + 1), fdist).x,
        textureLod(u_texture0, 1e-4 * pos.zx / (fdist + 2), fdist + 1).x, k));

    vec3 gcol = vec3(0.25, 0.55, 0.06);
    gcol *= 0.3 + mix(
        textureLod(u_texture1, 3e-5 * pos.xz / (fdist + 1), fdist).x,
        textureLod(u_texture1, 3e-5 * pos.xz / (fdist + 2), fdist + 1).x, k) * 1.9;

    float l = clamp01(pos.y * s / 70.0);

    col = mix(gcol, col, l);
    col *= mix(
        textureLod(u_texture0, 3e-2 * pos.xz / (fdist + 1), fdist).x,
        textureLod(u_texture0, 3e-2 * pos.xz / (fdist + 2), fdist + 1).x, k) * 3.2;

    return Material(col, 0.0);
}