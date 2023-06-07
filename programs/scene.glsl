Material materials[] = {
	Material(vec3(0.8, 0.8, 0.8), 0.5),  // default white
	Material(vec3(0.2, 0.2, 0.2), 0.5),  // gray (sword hilt)
	Material(vec3(0.2, 0.1, 0.07), 0.5), // brown (sword guard and ball)
	Material(vec3(0.8, 0.2, 0.2), 0.5),  // red (sword blade and amogus' color)
	Material(vec3(0.3, 0.6, 1.0), 0.5)   // light blue (eyes)
};


Object swordSDF(in vec3 pos, in vec3 dir) {
//    return Object(MIN_DIST, materials[2]);

    dir = normalize(dir);
    vec3 angles = dir2angles(dir);
    float scale = 0.1;
    pos /= scale;

    vec3 hiltP = pos + 4.6 * dir;
    rotate(hiltP, angles);

    vec3 guardP = pos + 8.0 * dir;
    rotate(guardP, angles);
    guardP.zx *= rotateMat(guardP.y / 10.0);

    vec3 bladeP = pos + 28.0 * dir;
    rotate(bladeP, angles);
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
    float leg1Dist = capsuleSDF(pos - vec3(-1.7, 0, -0.5), 2.3, 1);
    float leg2Dist = capsuleSDF(pos - vec3(1.7, 0, -0.5), 2.3, 1);
    float bodyDist = capsuleSDF(pos - vec3(0, 4, 0), 1.5, 3);
    float backpackDist = sdiff(capsuleSDF(pos - vec3(0, 4, 1), 1, 3), pos.z - 2.5, 1.0); //TODO: try later beveled box

    vec3 ep = pos - vec3(0, 5, -2);
    ep.xy *= rotateMat(1.57079632679);
    float eyesDist = capsuleSDF(ep, 1, 1.5);

    float b = min(leg1Dist, leg2Dist);
    b = smin(b, bodyDist, 0.7);
    b = smin(b, backpackDist, 0.4);

    Object body = Object(b, materials[3]);
    Object eyes = Object(eyesDist, materials[4]);

    return smin(body, eyes, 0.1);
}

Object sceneSDF(in vec3 pos, bool calcColor) {
    Object enemies = Object(MAX_DIST, materials[0]);
    Object sword = Object(MAX_DIST, materials[0]);

//    for (int i = 0; i < ENEMIES_COUNT; i++)
//        if (enemiesVisible[i])
//            enemies = min(enemies, amogusSDF(pos - u_enemiesPos[i]));

    if (swordVisible) {
        vec3 swordP = pos - u_camPos;
        swordP.zx *= rotateMat(u_camRot.x);
        swordP -= u_swordPos;
        sword = swordSDF(swordP, u_swordDir);
    }

//    return sword;

    if (!calcColor) {
        float d = min(enemies.dist, sword.dist);
        d = min(d, mapH(pos));
        return Object(d, materials[0]);
    }

//    return min(enemies, sword);

    vec2 groundDist = map(pos);
    Object ground = Object(groundDist.x, getMaterial(pos, groundDist));

    return min(ground, sword);
    return min(min(enemies, sword), ground);

    float t = u_time;
}
