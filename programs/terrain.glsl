#version 450 core

uniform vec2 u_resolution;
uniform float u_time;

uniform sampler2D u_texture0;
uniform sampler2D u_texture1;

uniform vec3 u_camPos;
uniform vec2 u_camRot;

uniform vec3 u_swordPos;
uniform vec3 u_swordRot;

layout(location = 0) out vec4 fragColor;

const mat2 m2 = mat2(1.6, -1.2, 1.2, 1.6);

float noi(in vec2 p) {
    return 0.5 * (cos(6.2831 * p.x) + cos(6.2831 * p.y));
}

float terrainLow(vec2 p) {
    p *= 0.0013;

    float s = 1.0;
    float t = 0.0;
    for (int i = 0; i < 2; i++) {
        t += s * noi(p);
        s *= 0.5 + 0.1 * t;
        p = 0.97 * m2 * p + (t - 0.5) * 0.2;
    }
    return t * 55.0;
}

float terrainMed(vec2 p) {
    p *= 0.0013;

    float s = 1.0;
    float t = 0.0;
    for (int i = 0; i < 6; i++) {
        t += s * noi(p);
        s *= 0.5 + 0.1 * t;
        p = 0.97 * m2 * p + (t - 0.5) * 0.2;
    }

    return t * 55.0;
}

float terrainHigh(vec2 p) {
    vec2 q = p;
    p *= 0.0013;

    float s = 1.0;
    float t = 0.0;
    for (int i = 0; i < 7; i++) {
        t += s * noi(p);
        s *= 0.5 + 0.1 * t;
        p = 0.97 * m2 * p + (t - 0.5) * 0.2;
    }

    t += 0.05 * textureLod(u_texture0, 0.001 * q, 0.0).x;
    t += 0.03 * textureLod(u_texture0, 0.005 * q, 0.0).x;
    t += t * 0.03 * textureLod(u_texture0, 0.020 * q, 0.0).x;

    return t * 55.0;
}

vec2 map(in vec3 pos) {
    float m = 0.0;
    float h = pos.y - terrainMed(pos.xz);
    return vec2(h, m);
}

float mapH(in vec3 pos) {
    float y = terrainHigh(pos.xz);
    float h = pos.y - y;

    return h;
}

vec2 interesct(in vec3 ro, in vec3 rd, in float tmin, in float tmax) {
    float t = tmin;
    float m = 0.0;
    for (int i = 0; i < 160; i++) {
        vec3 pos = ro + t * rd;
        vec2 res = map(pos);
        m = res.y;
        if (res.x < (0.001 * t) || t > tmax) break;
        t += res.x * 0.5;
    }

    return vec2(t, m);
}

vec3 calcNormalHigh(in vec3 pos, float t) {
    vec2 e = vec2(1.0, -1.0) * 0.001 * t;

    return normalize(e.xyy * mapH(pos + e.xyy) +
                     e.yyx * mapH(pos + e.yyx) +
                     e.yxy * mapH(pos + e.yxy) +
                     e.xxx * mapH(pos + e.xxx));
}

vec3 calcNormalMed(in vec3 pos, float t) {
    float e = 0.005 * t;
    vec2 eps = vec2(e, 0.0);
    float h = terrainMed(pos.xz);
    return normalize(vec3(terrainMed(pos.xz - eps.xy) - h, e, terrainMed(pos.xz - eps.yx) - h));
}

vec3 camPath(float time) {
    vec2 p = 1100.0 * vec2(cos(0.0 + 0.23 * time), cos(1.5 + 0.205 * time));
    return vec3(p.x, 0.0, p.y);
}

vec3 dome(in vec3 rd, in vec3 light1) {
    float sda = clamp(0.5 + 0.5 * dot(rd, light1), 0.0, 1.0);
    float cho = max(rd.y, 0.0);

    vec3 bgcol = mix(mix(vec3(0.00, 0.40, 0.60) * 0.7, vec3(0.80, 0.70, 0.20), pow(1.0 - cho, 3.0 + 4.0 - 4.0 * sda)),
    vec3(0.43 + 0.2 * sda, 0.4 - 0.1 * sda, 0.4 - 0.25 * sda), pow(1.0 - cho, 10.0 + 8.0 - 8.0 * sda));

    bgcol *= 0.8 + 0.2 * sda;
    return bgcol * 0.75;
}

mat3 setCamera(in vec3 ro, in vec3 ta, float cr)
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));
    return mat3(cu, cv, cw);
}

void main()
{
    float t0 = u_time;
    vec3 t1 = u_camPos;
    vec2 t2 = u_camRot;
    vec3 t3 = u_swordPos;
    vec3 t4 = u_swordRot;

    vec2 xy = -1.0 + 2.0 * gl_FragCoord.xy / u_resolution.xy;
    vec2 sp = xy * vec2(u_resolution.x / u_resolution.y, 1.0);

    // camera
    float cr = 0.18 * sin(-1.6);
    vec3 ro = camPath(16.0);
    vec3 ta = camPath(19.0);
    ro.y = terrainLow(ro.xz) + 60.0 + 10;
    ta.y = ro.y - 200.0;
    // camera to world transformation
    mat3 cam = setCamera(ro, ta, cr);

    // light
    vec3 light1 = normalize(vec3(-0.8, 0.2, 0.5));

    //--------------------------

    // generate ray
    vec3 rd = cam * normalize(vec3(sp.xy, 1.5));

    // background
    vec3 bgcol = dome(rd, light1);

    // raymarch
    float tmin = 10.0;
    float tmax = 4500.0;

    float sundotc = clamp(dot(rd, light1), 0.0, 1.0);
    vec3 col = bgcol;

    vec2 res = interesct(ro, rd, tmin, tmax);
    if (res.x > tmax)
    {
        // sky
        col += 0.2 * 0.12 * vec3(1.0, 0.5, 0.1) * pow(sundotc, 5.0);
        col += 0.2 * 0.12 * vec3(1.0, 0.6, 0.1) * pow(sundotc, 64.0);
        col += 0.2 * 0.12 * vec3(2.0, 0.4, 0.1) * pow(sundotc, 512.0);

        // clouds
        vec2 sc = ro.xz + rd.xz * (1000.0 - ro.y) / rd.y;
        col = mix(col, 0.25 * vec3(0.5, 0.9, 1.0), 0.4 * smoothstep(0.0, 1.0, texture(u_texture0, 0.000005 * sc).x));

        // sun scatter
        col += 0.2 * 0.2 * vec3(1.5, 0.7, 0.4) * pow(sundotc, 4.0);
    }
    else
    {
        // mountains
        float t = res.x;
        vec3 pos = ro + t * rd;
        vec3 nor = calcNormalHigh(pos, t);
        vec3 sor = calcNormalMed(pos, t);
        vec3 ref = reflect(rd, nor);

        // rock
        col = vec3(0.07, 0.06, 0.05);
        col *= 0.2 + sqrt(texture(u_texture0, 0.01 * pos.xy * vec2(0.5, 1.0)).x *
          texture(u_texture0, 0.01 * pos.zy * vec2(0.5, 1.0)).x);
        vec3 col2 = vec3(1.0, 0.2, 0.1) * 0.01;
        col = mix(col, col2, 0.5 * res.y);

        // grass
        float s = smoothstep(0.6, 0.7, nor.y - 0.01 * (pos.y - 20.0));
        s *= smoothstep(0.15, 0.2, 0.01 * nor.x + texture(u_texture0, 0.001 * pos.zx).x);
        vec3 gcol = 0.13 * vec3(0.22, 0.33, 0.04);
        gcol *= 0.3 + texture(u_texture1, 0.03 * pos.xz).x * 1.4;
        col = mix(col, gcol, s);
        col *= texture( u_texture0, 0.3*pos.xz ).x*3.2;
        nor = mix(nor, sor, 0.3 * s);
        vec3 ptnor = nor;

        // snow
        s = ptnor.y + 0.008 * pos.y - 0.2 + 0.2 * (texture(u_texture1, 0.00015 * pos.xz + 0.0 * sor.y).x - 0.5);
        float sf = fwidth(s) * 1.5;
        s = smoothstep(0.84 - sf, 0.84 + sf, s);
        col = mix(col, 0.15 * vec3(0.42, 0.6, 0.8), s);
        nor = mix(nor, sor, 0.5 * smoothstep(0.9, 0.95, s));

        // lighting
        float amb = clamp(nor.y, 0.0, 1.0);
        float dif = clamp(dot(light1, nor), 0.0, 1.0);
        col *= dif * vec3(11.0, 6.0, 3.0) + amb * vec3(0.25, 0.3, 0.4);

        // fog
        col = mix(col, 0.25 * mix(vec3(0.4, 0.75, 1.0), vec3(0.3, 0.3, 0.3), sundotc * sundotc), 1.0 - exp(-0.0000008 * t * t));

        // sun scatter
        col += 0.15 * vec3(1.0, 0.8, 0.3) * pow(sundotc, 8.0) * (1.0 - exp(-0.003 * t));

        // background
        col = mix(col, bgcol, 1.0 - exp(-0.00000004 * t * t));
    }

    // gamma
    col = pow(col, vec3(0.45));

    // color grading
    col *= vec3(1.4, 1.4, 1.65);
    col = clamp(col, 0.0, 1.0);
    col *= col * (3.0 - 2.0 * col);
    col = mix(col, vec3(dot(col, vec3(0.333))), -0.2);

    fragColor = vec4(col, 1.0);
}
