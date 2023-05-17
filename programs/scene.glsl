Material materials[] = {
	Material(vec3(0.8, 0.2, 0.2), 0.5),
	Material(vec3(0.2, 0.8, 0.2), 0.5),
	Material(vec3(0.2, 0.2, 0.8), 0.5),
	Material(vec3(0.8, 0.8, 0.8), 0.5),
	Material(vec3(0.8, 0.8, 0.2), 0.5)
};

float swordSDF(in vec3 origin, in vec3 dir) {
    float rad = 1;
    float d = sphereSDF(origin, rad);
    for (int i = 0; i < 10; i++) {
        dir = normalize(dir) * rad * 1.5;
        origin += dir;
        rad -= 0.03;

        d = smin(d, sphereSDF(origin, rad), 0.7);
    }
    return d;
}


Object sceneSDF(in vec3 pos, in bool calcColor) {
    float sphereDist = sphereSDF(pos - vec3(2.0, 4.0 + cos(u_time), 2.0), 0.5);
//    float torus1Dist = torusSDF(pos - vec3(2.0, 1.0, 2.0), vec2(2.0 + sin(u_time), 1));
//    float boxDist = boxSDF(pos - vec3(2.0, 3.0, 2.0), vec3(1.0, 0.3, 1.0));
//    float groundDist = groundSDF(pos);
    float swordDist = swordSDF(pos - u_swordPos, u_swordRot);

    if (!calcColor) {
        float d = min(sphereDist, swordDist);
//        float d = sdiff(groundDist, torus1Dist, 0.7);
//        d = smin(d, sdiff(boxDist, sphereDist, 0.7), 0.7);
    	return Object(d, materials[0]);
    }

//    Object ground = Object(groundDist, materials[1]);
    Object sphere = Object(sphereDist, materials[0]);
    Object sword = Object(swordDist, materials[2]);
//    Object torus1 = Object(torus1Dist, materials[1]);
//    Object box = Object(boxDist, materials[4]);

    Object o = min(sphere, sword);
//    Object o = sdiff(ground, torus1, 0.7);
//    o = smin(o, sdiff(box, sphere, 0.7), 0.7);
    return o;
}
