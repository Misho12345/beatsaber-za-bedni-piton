vec3 normal(vec3 p) {
   	vec2 e = vec2(0.01, 0.0);
    vec3 n = vec3(sceneSDF(p, false).dist) -
	    vec3(sceneSDF(p - e.xyy, false).dist,
		    sceneSDF(p - e.yxy, false).dist,
		    sceneSDF(p - e.yyx, false).dist);
    return normalize(n);
}

float getSoftShadow(vec3 p, vec3 lightPos) {
    float res = 1.0;
    float dist = 0.01;
    float lightSize = 0.07;
    for (int i = 0; i < MAX_MARCH_STEPS; i++) {
        float hit = sceneSDF(p + lightPos * dist, false).dist;
        res = min(res, hit / (dist * lightSize));
        dist += hit;
        if (hit < 0.0001 || dist > 60.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

float getAmbientOcclusion(vec3 p, vec3 normal) {
    float occ = 0.0;
    float weight = 1.0;
    for (int i = 0; i < 8; i++) {
        float len = 0.01 + 0.02 * float(i * i);
        float dist = sceneSDF(p + normal * len, false).dist;
        occ += (len - dist) * weight;
        weight *= 0.85;
    }
    return 1.0 - clamp(0.6 * occ, 0.0, 1.0);
}

vec3 getLight(vec3 p, vec3 rd, Material mat) {
    vec3 lightPos = vec3(-20.0, 55.0, 25.0);
    vec3 L = normalize(lightPos - p);
    vec3 N = normal(p);
    vec3 V = -rd;
    vec3 R = reflect(-L, N);

    vec3 color = mat.albedo;

    vec3 specular = 1.3 * vec3(mat.specular) * pow(clamp(dot(R, V), 0.0, 1.0), 10.0);
    vec3 diffuse = 0.9 * color * clamp(dot(L, N), 0.0, 1.0);
    vec3 ambient = 0.07 * color;
    vec3 fresnel = 0.15 * color * pow(1.0 + dot(rd, N), 3.0);

    float shadow = getSoftShadow(p + N * 0.02, normalize(lightPos));
    float occ = getAmbientOcclusion(p, N);
    vec3 back = 0.05 * color * clamp(dot(N, -L), 0.0, 1.0);

    return (back + ambient + fresnel) * occ + (specular * occ + diffuse) * shadow;
}