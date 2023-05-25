Material materials[] = {
	Material(vec3(0.8, 0.8, 0.8), 0.5),  // default white
	Material(vec3(0.2, 0.2, 0.2), 0.5),  // gray
	Material(vec3(0.2, 0.1, 0.07), 0.5), // brown
	Material(vec3(0.8, 0.2, 0.2), 0.5)   // red
};


Object swordSDF(in vec3 pos, in vec3 dir) {
    dir = normalize(dir);

    float scale = 0.1;
    pos /= scale;

    vec3 hiltP = pos + 4.6 * dir;
    rotate(hiltP, dir2angles(dir));

    vec3 guardP = pos + 8.0 * dir;
    rotate(guardP, dir2angles(dir));
    guardP.zx *= rotateMat(guardP.y / 10.0);

    vec3 bladeP = pos + 28.0 * dir;
    rotate(bladeP, dir2angles(dir));
    bladeP.yz *= rotateMat(bladeP.x / 10.0);

    float b1 = mix(0.0, 0.8, 1 - clamp01(bladeP.x / 27.0));
    float b2 = mix(0.6, 0.8, 1 - clamp01((abs(bladeP.x - 5.0) + 5.0) / 27.0));
    float b = min(b1, b2);

    Object hilt = Object(cylinderSDF(hiltP, 0.7 + abs(sin(hiltP.x * 2.0) / 10.0), 7.0), materials[1]);
    Object sphereAndGuard = Object(min(sphereSDF(pos, 1.4), cylinderSDF(guardP, 3.0, 0.45)), materials[2]);
    Object blade = Object(boxSDF(bladeP, vec3(20, b, b)), materials[3]);

    Object res = smin(smin(hilt, sphereAndGuard, 0.3), blade, 0.7);
    res.dist *= scale;
    return res;
}

Object amogusSDF(in vec3 pos) {
    vec3 p = pos - vec3(0, 80, 0);
    float plane = p.y + sin(u_time) * 5 - 5;

    float leg1 = capsuleSDF(p + vec3(1.7, 0, 1), vec3(0, 2, 0), vec3(0, -2, 0), 1);
    float leg2 = capsuleSDF(p - vec3(1.7, 0, 1), vec3(0, 2, 0), vec3(0, -2, 0), 1);
    float body = capsuleSDF(p - vec3(0, 4.0, 0), vec3(0, 2, 0), vec3(0, -2, 0), 3);

//    float b = boxSDF(p, vec3(2.0));
//    float s = sphereSDF(p + vec3(0, 1, 0), 2.0);
//    float c = capsuleSDF(p, vec3(3, 0, 0), vec3(-3, 0, 0), 1);
//
//    float bc = abs(min(min(b, c), s)) - 0.2;

    float d = min(leg1, leg2);
    d = smin(d, body, 0.7);
    d = abs(d) - 0.2;

    return Object(smax(d, plane, 0.3) / 2.0, materials[3]);
}

Object sceneSDF(in vec3 pos, bool calcColor) {
//    return amogusSDF(pos);

    vec3 swordP = pos - u_camPos;
    rotate(swordP, dir2angles(orientation));
    swordP -= u_swordPos;

    Object sword = swordSDF(swordP, u_swordDir);

    if (!calcColor) {
        float groundDist = mapH(pos);
        return Object(min(sword.dist, groundDist), materials[0]);
    }

    vec2 groundDist = map(pos);
    Object ground = Object(groundDist.x, getMaterial(pos, groundDist));

    return min(sword, ground);

    float t = u_time;
}
