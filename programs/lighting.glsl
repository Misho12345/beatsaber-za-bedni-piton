vec3 dome(in vec3 rd, in vec3 light1) {
    float sda = clamp01(0.5 + 0.5 * dot(rd, light1));
    float cho = max(rd.y, 0.0);

    vec3 bgcol = mix(mix(vec3(0.0, 0.28, 0.42), vec3(0.8, 0.7, 0.2), pow(1.0 - cho, 7.0 - 4.0 * sda)),
    vec3(0.43 + 0.2 * sda, 0.4 - 0.1 * sda, 0.4 - 0.25 * sda), pow(1.0 - cho, 18.0 - 8.0 * sda));

    bgcol *= 0.8 + 0.2 * sda;
    return bgcol * 0.75;
}

vec3 normal(in vec3 pos) {
   	vec2 e = vec2(EPS, 0.0);
    return normalize(vec3(
        sceneSDF(pos + e.xyy, false).dist - sceneSDF(pos - e.xyy, false).dist,
        sceneSDF(pos + e.yxy, false).dist - sceneSDF(pos - e.yxy, false).dist,
        sceneSDF(pos + e.yyx, false).dist - sceneSDF(pos - e.yyx, false).dist
    ));
}

float calcShadow(in vec3 pos, in vec3 lightDir) {
    float totalDist = 0.0;
    float shadow = 1.0;
    float lightSize = 0.8;

    for (int i = 0; i < MAX_SHADOW_MARCH_STEPS; i++) {
        float dist = sceneSDF(pos + totalDist * lightDir, false).dist;
        totalDist += dist;
        shadow = min(shadow, dist / (totalDist * lightSize));

        if (abs(dist) < MIN_DIST || totalDist > MAX_SHADOW_DIST) break;
    }

    return clamp(shadow, 0.15, 1.0);
}

float getAmbientOcclusion(in vec3 pos, in vec3 normal) {
    float occ = 0.0;
    float weight = 1.0;
    for (int i = 0; i < 8; i++) {
        float len = 0.01 + 0.02 * float(i * i);
        float dist = sceneSDF(pos + normal * len, false).dist;
        occ += (len - dist) * weight;
        weight *= 0.85;
    }
    return 1.0 - clamp01(0.6 * occ);
}

vec3 getLight(in vec3 pos, in vec3 rayDir, in Material mat, in vec3 lightDir) {
    vec3 L = normalize(lightDir);
    vec3 N = normal(pos);
    vec3 V = -rayDir;
    vec3 R = reflect(-L, N);

    vec3 color = mat.albedo;

    vec3 diffuse = 0.9 * color * clamp01(dot(L, N));
    vec3 specular = 1.3 * vec3(mat.specular) * pow(clamp01(dot(R, V)), 10.0);
    vec3 ambient = 0.07 * color;
    vec3 fresnel = 0.15 * color * pow(1.0 + dot(rayDir, N), 3.0);

    float shadow = calcShadow(pos + 0.02 * N, L);
    float occ = getAmbientOcclusion(pos, N);
    vec3 back = 0.05 * color * clamp01(dot(N, -L));

    return (back + ambient + fresnel) * occ + (specular * occ + diffuse) * shadow;
}