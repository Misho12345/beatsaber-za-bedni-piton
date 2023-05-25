struct Material {
	vec3 albedo;
	float specular;
};

struct Object {
	float dist;
	Material mat;
};

float clamp01(float v) {
	return clamp(v, 0.0, 1.0);
}

float planeSDF(in vec3 pos, vec3 dir) {
	return pos.y + dot(dir, pos);
}

float sphereSDF(in vec3 pos, float radius) {
    return length(pos) - radius;
}

float torusSDF(in vec3 pos, in vec2 r1r2) {
    vec2 q = vec2(length(pos.zy) - r1r2.x, pos.x);
    return length(q) - r1r2.y;
}

float boxSDF(in vec3 p, in vec3 b) {
	vec3 d = abs(p) - b;
  	return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float cylinderSDF(vec3 p, float r, float h) {
    vec3 axis = vec3(0.0, p.y, p.z);
    float d = length(axis) - r;
    float dx = abs(p.x) - h / 2.0;
    return max(d, dx);
}

float capsuleSDF(vec3 p, float h, float r) {
    vec3 pa = abs(p) - vec3(0.0, h, 0.0);
    return length(max(pa, 0.0)) + min(max(pa.x, max(pa.y, pa.z)), 0.0) - r;
}

Material mix(in Material m1, in Material m2, float k) {
	return Material(
		mix(m1.albedo, m2.albedo, k),
		mix(m1.specular, m2.specular, k)
	);
}

float smin(float d1, float d2, float k) {
    float h = clamp01(0.5 + 0.5 * (d2 - d1) / k);
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

Object min(in Object obj1, in Object obj2) {
	return (obj1.dist < obj2.dist) ? obj1 : obj2;
}

Object max(in Object obj1, in Object obj2) {
	return (obj1.dist > obj2.dist) ? obj1 : obj2;
}

Object diff(in Object obj1, in Object obj2) {
	return (obj1.dist > -obj2.dist) ? obj1 : Object(-obj2.dist, obj2.mat);
}

Object smin(in Object obj1, in Object obj2, float k) {
	float dist = smin(obj1.dist, obj2.dist, k);
	Material mat = mix(obj1.mat, obj2.mat, smoothstep(obj1.dist, -obj2.dist, 0.0));
	return Object(dist, mat);
}

Object smax(in Object obj1, in Object obj2, float k) {
	float dist = smax(obj1.dist, obj2.dist, k);
	Material mat = mix(obj1.mat, obj2.mat, smoothstep(obj1.dist, -obj2.dist, 0.0));
	return Object(dist, mat);
}

Object sdiff(in Object obj1, in Object obj2, float k) {
	float dist = sdiff(obj1.dist, obj2.dist, k);
	Material mat = mix(obj1.mat, obj2.mat, smoothstep(obj1.dist, obj2.dist, 0.0));
	return Object(dist, mat);
}

vec3 dir2angles(vec3 dir) {
    float roll = 0.0;
    float yaw = 3.14159265359 + atan(dir.z, dir.x);
    float pitch = atan(dir.y, length(dir.xz));

    return vec3(roll, yaw, pitch);
}

mat2 rotateMat(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 rotate(inout vec3 p, in vec3 a) {
	p.yz *= rotateMat(a.x);
    p.zx *= rotateMat(a.y);
    p.xy *= rotateMat(a.z);

	return p;
}