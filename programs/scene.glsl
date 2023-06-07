Material materials[] = {
	Material(vec3(0.8, 0.8, 0.8), 0.5),  // default white
	Material(vec3(0.2, 0.2, 0.2), 0.5),  // gray (sword hilt)
	Material(vec3(0.2, 0.1, 0.07), 0.5), // brown (sword guard and ball)
	Material(vec3(0.8, 0.2, 0.2), 0.5),  // red (sword blade and amogus' color)
	Material(vec3(0.3, 0.6, 1.0), 0.5)   // light blue (eyes)
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

    float leg1Dist = capsuleSDF(p - vec3(-1.7, 0, -0.5), 2.3, 1);
    float leg2Dist = capsuleSDF(p - vec3(1.7, 0, -0.5), 2.3, 1);
    float bodyDist = capsuleSDF(p - vec3(0, 4, 0), 1.5, 3);
    float backpackDist = sdiff(capsuleSDF(p - vec3(0, 4, 1), 1, 3), p.z - 2.5, 1.0); //TODO: try later beveled box

    vec3 ep = p - vec3(0, 5, -2);
    ep.xy *= rotateMat(3.14/2);
    float eyesDist = capsuleSDF(ep, 1, 1.5);

    float b = min(leg1Dist, leg2Dist);
    b = smin(b, bodyDist, 0.7);
    b = smin(b, backpackDist, 0.4);

    Object body = Object(b, materials[3]);
    Object eyes = Object(eyesDist, materials[4]);

    Object res = smin(body, eyes, 0.1);
    res.dist = abs(res.dist) - 0.2;
    res.dist = smax(res.dist, p.y + sin(u_time) * 5 - 4 , 0.7);

    return res;
}

Object sceneSDF(in vec3 pos, bool calcColor) {
    Object enemies = amogusSDF(pos);//Object(MAX_DIST, materials[0]);
//    for (int i = 0; i < ENEMIES_COUNT; i++) {
//        Object newCube = Object(boxSDF(u_enemyPos[i], vec3(1)), materials[0]);
//        enemies = min(newCube, enemies);
//    }
//    return enemies;

    vec3 swordP = pos - u_camPos;
    rotate(swordP, dir2angles(orientation));
    swordP -= u_swordPos;
    Object sword = swordSDF(swordP, u_swordDir);

    //return min(enemies, sword);

    if (!calcColor) {
        float groundDist = mapH(pos);
        return Object(min(sword.dist, groundDist), materials[0]);
    }

    vec2 groundDist = map(pos);
    Object ground = Object(groundDist.x, getMaterial(pos, groundDist));

    return min(sword, ground);

    float t = u_time;
}
