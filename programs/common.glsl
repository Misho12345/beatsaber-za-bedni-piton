struct Material {
	vec3 albedo;
	float specular;
};

struct Object {
	float dist;
	Material mat;
};

float sphereSDF(vec3 pos, float radius) {
    return length(pos) - radius;
}

float torusSDF(vec3 pos, vec2 r1r2) {
    vec2 q = vec2(length(pos.zy) - r1r2.x, pos.x);
    return length(q) - r1r2.y;
}

float boxSDF(vec3 p, vec3 b) {
	vec3 d = abs(p) - b;
  	return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

Material mix(Material m1, Material m2, float k) {
	return Material(
		mix(m1.albedo, m2.albedo, k),
		mix(m1.specular, m2.specular, k)
	);
}

float smin(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

float smax(float a, float b, float k) {
    return smin(a, b, -k);
}

float sdiff(float a, float b, float k) {
    return smax(a, -b, k);
}

float diff(float a, float b) {
    return max(a, -b);
}

Object min(Object obj1, Object obj2) {
	return (obj1.dist < obj2.dist) ? obj1 : obj2;
}

Object max(Object obj1, Object obj2) {
	return (obj1.dist > obj2.dist) ? obj1 : obj2;
}

Object diff(Object obj1, Object obj2) {
	return (obj1.dist > -obj2.dist) ? obj1 : Object(-obj2.dist, obj2.mat);
}

Object smin(Object obj1, Object obj2, float k) {
	float dist = smin(obj1.dist, obj2.dist, k);
	Material mat = mix(obj1.mat, obj2.mat, smoothstep(obj1.dist, -obj2.dist, 0.0));
	return Object(dist, mat);
}

Object smax(Object obj1, Object obj2, float k) {
	float dist = smax(obj1.dist, obj2.dist, k);
	Material mat = mix(obj1.mat, obj2.mat, smoothstep(obj1.dist, -obj2.dist, 0.0));
	return Object(dist, mat);
}

Object sdiff(Object obj1, Object obj2, float k) {
	float dist = sdiff(obj1.dist, obj2.dist, k);
	Material mat = mix(obj1.mat, obj2.mat, smoothstep(obj1.dist, obj2.dist, 0.0));
	return Object(dist, mat);
}