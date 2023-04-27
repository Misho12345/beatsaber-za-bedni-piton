#version 450 core

layout (location = 0) out vec4 fragColor;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec3 u_camPos;
uniform vec2 u_camRot;

#define MAX_MARCH_STEPS 200
#define MIN_DIST 0.01
#define MAX_DIST 100.0
#define FOV tan(radians(60.0))

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


Material materials[] = {
	Material(vec3(0.8, 0.2, 0.2), 0.5),
	Material(vec3(0.2, 0.8, 0.2), 0.5),
	Material(vec3(0.2, 0.2, 0.8), 0.5),
	Material(vec3(0.8, 0.8, 0.8), 0.5),
	Material(vec3(0.8, 0.8, 0.2), 0.5)
};

Object sceneSDF(vec3 pos, bool calcColor) {
    float sphereDist = sphereSDF(pos - vec3(2.0, 4.0 + cos(u_time), 2.0), 0.5);
    float torus1Dist = torusSDF(pos - vec3(2.0, 1.0, 2.0), vec2(2.0 + sin(u_time), 1));
    float boxDist = boxSDF(pos - vec3(2.0, 3.0, 2.0), vec3(1.0, 0.3, 1.0));
    float planeDist = pos.y;

    if (!calcColor) {
        float d = sdiff(pos.y, torus1Dist, 0.7);
        d = smin(d, sdiff(boxDist, sphereDist, 0.7), 0.7);
    	return Object(d, materials[0]);
    }

    Object plane = Object(pos.y, materials[3]);
    Object sphere = Object(sphereDist, materials[0]);
    Object torus1 = Object(torus1Dist, materials[1]);
    Object box = Object(boxDist, materials[4]);

    Object o = sdiff(plane, torus1, 0.7);
    o = smin(o, sdiff(box, sphere, 0.7), 0.7);
    return o;
}

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
    return clamp(res, 0., 1.0);
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

    vec3 specColor = vec3(mat.specular);
    vec3 specular = 1.3 * specColor * pow(clamp(dot(R, V), 0.0, 1.0), 10.0);
    vec3 diffuse = 0.9 * color * clamp(dot(L, N), 0.0, 1.0);
    vec3 ambient = 0.07 * color;
    vec3 fresnel = 0.15 * color * pow(1.0 + dot(rd, N), 3.0);

    float shadow = getSoftShadow(p + N * 0.02, normalize(lightPos));
    float occ = getAmbientOcclusion(p, N);
    vec3 back = 0.05 * color * clamp(dot(N, -L), 0.0, 1.0);

    return (back + ambient + fresnel) * occ + (specular * occ + diffuse) * shadow;
}

vec3 getSky(vec2 uv, float AR, vec3 rayDir) {
    vec3 _betaR = vec3(1.95e-2, 1.1e-1, 2.94e-1);
    vec3 _betaM = vec3(4e-2, 4e-2, 4e-2);

    vec3 Ds = normalize(vec3(AR / -2.0, -0.5, FOV / -2.0));

    vec3 O = vec3(0.0, 1.0, 0.0);
    vec3 D = rayDir;

    vec3 color = vec3(0.0);

    if (D.y < -1) {
        float L = -O.y / D.y;
        O = O + D * L;
        D.y = -D.y;
        D = normalize(D);
    } else {
        float L1 = O.y / D.y;
        vec3 O1 = O + D * L1;

        vec3 D1 = vec3(1.0);
        D1 = normalize(D);
    }

    float t = max(0.001, D.y) + max(-D.y, -0.001);

    float sR = 1 / t;
    float sM = 1.2 / t;

    float cosine = clamp(dot(D, Ds), 0.0, 1.0);
    vec3 extinction = exp(-(_betaR * sR + _betaM * sM));

    float fcos2 = cosine * cosine;

    vec3 inScatter = (1. + fcos2) * vec3(1 + _betaM / _betaR * 0);

    color = inScatter * (1.0 - extinction); // *vec3(1.6,1.4,1.0)

    float tA = 2.51;
    float tB = 0.03;
    float tC = 2.43;
    float tD = 0.59;
    float tE = 0.14;
    color = clamp((color * (tA * color + tB)) / (color * (tC * color + tD) + tE), 0.0, 1.0);

    color = pow(color, vec3(2.2));

    return color;
}

vec3 raymarch(vec3 rayOrigin, vec3 rayDir, vec2 uv, float AR) {
    float dist = 0.0;
    float totalDist = 0.0;

    vec3 sky = getSky(uv, AR, rayDir);

    for (int i = 0; i < MAX_MARCH_STEPS; i++) {
        Object scene = sceneSDF(rayOrigin + totalDist * rayDir, true);
        dist = scene.dist;
        totalDist += dist;
        if (dist < MIN_DIST) {
            vec3 pos = rayOrigin + totalDist * rayDir;
            vec3 col = getLight(pos, rayDir, scene.mat);
           	return col;
            return mix(col, sky, 1.0 - exp(-1e-7 * dist * dist * dist));
        }

        if (totalDist > MAX_DIST) {
            return sky;
        }
    }
}

mat3 getCam() {
    vec3 camF = vec3(
        cos(u_camRot.x) * cos(u_camRot.y),
        sin(u_camRot.y),
        sin(u_camRot.x) * cos(u_camRot.y)
    );

    vec3 camR = normalize(cross(vec3(0, 1, 0), camF));
    vec3 camU = cross(camF, camR);
    return mat3(camR, camU, camF);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy * 2.0 - 1.0;
    float AR = u_resolution.x / u_resolution.y;
    uv.x *= AR;

    vec3 rayDir = getCam() * normalize(vec3(uv, FOV));
	vec3 rayOrigin = u_camPos;

	vec3 color = raymarch(rayOrigin, rayDir, uv, AR);
	fragColor = vec4(color, 1.0);
}
