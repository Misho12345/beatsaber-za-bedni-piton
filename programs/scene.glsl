Material materials[] = {
	Material(vec3(0.6, 0.5, 0.2), 0.5),
	Material(vec3(0.2, 0.2, 0.2), 0.5),
	Material(vec3(0.3, 0.2, 0.1), 0.5),
	Material(vec3(0.8, 0.2, 0.2), 0.5)
};


Object swordSDF(in vec3 pos, in vec3 dir) {
    dir = normalize(dir);

    vec3 hiltP = rotate(pos + 4.6 * dir, dir2angles(dir));

    vec3 guardP = rotate(pos + 8 * dir, dir2angles(dir));
    guardP.zx *= rotateMat(guardP.y / 7.0);

    vec3 bladeP = rotate(pos + 28 * dir, dir2angles(dir));
    bladeP.yz *= rotateMat(bladeP.x / 10);

    float b1 = mix(0.0, 0.8, 1 - clamp01(bladeP.x / 27));
    float b2 = mix(0.6, 0.8, 1 - clamp01((abs(bladeP.x - 5) + 5) / 27));
    float b = min(b1, b2);

    Object sphere = Object(sphereSDF(pos, 1.4), materials[2]);
    Object hilt = Object(cylinderSDF(hiltP, 0.7 + abs(sin(hiltP.x * 2) / 10.0), 7), materials[1]);
    Object guard = Object(cylinderSDF(guardP, 3, 0.45), materials[2]);
    Object blade = Object(boxSDF(bladeP, vec3(20, b, b)), materials[3]);

    return smin(smin(smin(hilt, sphere, 0.3), guard, 0.7), blade, 0.7);
}

Object sceneSDF(in vec3 pos, bool calcColor) {
    return swordSDF(pos - u_swordPos, u_swordRot);

    if (!calcColor) {
        float groundDist = mapH(pos);
        return Object(groundDist, materials[0]);
    }

    vec2 groundDist = map(pos);
    Object ground = Object(groundDist.x, getMaterial(pos, groundDist));

    return ground;

    float t = u_time;
}
