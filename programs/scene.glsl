Material materials[] = {
	Material(vec3(0.8, 0.2, 0.2), 0.5),
	Material(vec3(0.2, 0.8, 0.2), 0.5),
	Material(vec3(0.2, 0.2, 0.8), 0.5),
	Material(vec3(0.8, 0.8, 0.8), 0.5),
	Material(vec3(0.8, 0.8, 0.2), 0.5)
};

//#define PI 3.14159
//
//float swordSDF(in vec3 pos, in vec3 dir) {
//    float sphere = sphereSDF(pos, 1.4);
//
//    vec3 rot = dir2angles(dir);
//    vec3 bp = pos;
//    bp = (rotateX(rot.x) * rotateY(rot.y) * rotateZ(rot.z) * vec4(bp, 1.0)).xyz;
//
//    float box = boxSDF(bp, vec3(5, 1, 1));
//
//    return smin(box, sphere, 0.5);
//}

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

Object sceneSDF(in vec3 pos, bool calcColor) {
    return Object(swordSDF(pos - u_swordPos, u_swordRot), materials[1]);

    if (!calcColor) {
        float groundDist = mapH(pos);
        return Object(groundDist, materials[0]);
    }

    vec2 groundDist = map(pos);
    Object ground = Object(groundDist.x, getMaterial(pos, groundDist));

    return ground;

    float t = u_time;
}
