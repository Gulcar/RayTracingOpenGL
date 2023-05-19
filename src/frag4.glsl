#version 430 core

out vec4 FragColor;

uniform float uWinWidth;
uniform float uWinHeight;
uniform vec3 uBotLeftRayDir;
uniform vec3 uCamRight;
uniform vec3 uCamUp;
uniform vec3 uRayOrigin;
uniform float uTMin;
uniform int uMaxRayDepth;
uniform int uImageFrames;
uniform float uReflectAmount;
uniform float uDOFStrength;
uniform float uDOFDist;

layout(rgba32f, binding = 0) uniform image2D uAvgImage;

struct Ray
{
    vec3 origin;
    vec3 dir;
};

struct HitInfo
{
    vec3 point;
    vec3 normal;
    float t;
};

struct Sphere
{
    vec3 position;
    float radius;
    vec3 color;
    float reflectAmount;
};

struct Triangle
{
    vec3 v0;
    vec3 v1;
    vec3 v2;
};

const int numSpheres = 3;
Sphere spheres[numSpheres];

vec2 randCoords;

float rand()
{
    randCoords *= 1.1;
    return fract(sin(dot(randCoords, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 randVec2()
{
    vec2 v;
    v.x = rand() * 2.0 - 1.0;
    v.y = rand() * 2.0 - 1.0;
    return v;
}

vec3 randVec3()
{
    vec3 v;
    v.x = rand() * 2.0 - 1.0;
    v.y = rand() * 2.0 - 1.0;
    v.z = rand() * 2.0 - 1.0;
    return v;
}

vec3 randInSphere()
{
    for (int i = 0; i < 100; i++)
    {
        vec3 r = randVec3();
        //if (length(r) <= 1.0)
        if (dot(r,r) <= 1.0)
            return r;
    }
    return vec3(0.0);
}

vec3 BackgroundColor(Ray ray)
{
    ray.dir = normalize(ray.dir);

    float y = ray.dir.y;
    y = y / 2.0 + 0.5;

    vec3 bottomColor = vec3(0.8, 0.9, 1.0);
    vec3 topColor = vec3(0.6, 0.8, 1.0);

    return mix(bottomColor, topColor, y);
}

bool IntersectSphere(Ray ray, vec3 center, float radius, float tmax, inout HitInfo hit)
{
    vec3 oc = ray.origin - center;

    float a = dot(ray.dir, ray.dir);
    float b = dot(ray.dir, oc);
    float c = dot(oc, oc) - radius * radius;

    float D = b * b - a * c;
    if (D < 0.0) return false;

    float sqrtD = sqrt(D);
    
    float x = (-b - sqrtD) / a;
    if (x < uTMin || x > tmax)
    {
        x = (-b + sqrtD) / a;
        if (x < uTMin || x > tmax)
            return false;
    }

    hit.point = ray.origin + ray.dir * x;
    hit.normal = normalize(hit.point - center);
    hit.t = x;

    return true;
}

bool IntersectGroundPlane(Ray ray, float planeY, float tmax, inout HitInfo hit)
{
    // P = O + tD
    // Py = Oy + tDy
    // t = (Py - Oy) / Dy

    float t = (planeY - ray.origin.y) / ray.dir.y;

    // ce je ray.dir.y == 0.0 in dobimo t = +-inf tukej vrnemo false
    if (t < uTMin || t > tmax)
        return false;

    hit.point = ray.origin + ray.dir * t;
    hit.normal = (ray.dir.y > 0.0) ? vec3(0, -1, 0) : vec3(0, 1, 0);
    hit.t = t;

    return true;
}

float TriangleArea(vec3 a, vec3 b, vec3 c)
{
    return length(cross(b - a, c - a)) / 2.0;
}

bool IntersectTriangle(Ray ray, Triangle tri, float tmax, inout HitInfo hit)
{
    vec3 edge1 = tri.v1 - tri.v0;
    vec3 edge2 = tri.v2 - tri.v0;

    vec3 normal = normalize(cross(edge2, edge1));

    if (dot(normal, ray.dir) == 0.0)
        return false; // ray je vzporeden s ravnino (plane) na kateri je trikotnik

    // plane equation
    // (p - p0) . n = 0
    // plane intersection (https://en.wikipedia.org/wiki/Line%E2%80%93plane_intersection)
    // (O + tD - p0) . n = 0
    // t(D . n) + (O - p0) . n = 0
    // t = ((po - O) . n) / (D . n)

    float t = dot((tri.v0 - ray.origin), normal) / dot(ray.dir, normal);
    if (t < uTMin || t > tmax)
        return false;

    // https://www.youtube.com/watch?v=HYAgJN3x4GA
    // P = A + w(B-A) + v(C-A)
    // O + tD = A + w(B-A) + v(C-A)

    vec3 p = ray.origin + ray.dir * t;

    float a0 = TriangleArea(tri.v0, tri.v1, p);
    float a1 = TriangleArea(tri.v0, tri.v2, p);
    float a2 = TriangleArea(tri.v2, tri.v1, p);
    float a = TriangleArea(tri.v0, tri.v1, tri.v2);

    // tole z ploscinami ni najboljs ampak je neki

    if (a0 + a1 + a2 > a + 0.001)
        return false;

    hit.point = p;
    hit.normal = normal;
    hit.t = t;

    return true;
}

void IntersectRectX(Ray ray, float po, vec2 limitsY, vec2 limitsZ, inout float tmax, inout HitInfo hit, inout bool didHit)
{
    // P = O + tD
    // Px = Ox + tDx
    // t = (Px - Ox) / Dx

    float t = (po - ray.origin.x) / ray.dir.x;

    if (t < uTMin || t > tmax)
        return;

    vec3 p = ray.origin + ray.dir * t;

    if (p.y < limitsY.x || p.y > limitsY.y)
        return;
    if (p.z < limitsZ.x || p.z > limitsZ.y)
        return;

    hit.point = ray.origin + ray.dir * t;
    hit.normal = (po < ray.origin.x) ? vec3(1, 0, 0) : vec3(-1, 0, 0);
    hit.t = t;

    tmax = t;

    didHit = true;
}

void IntersectRectY(Ray ray, float po, vec2 limitsX, vec2 limitsZ, inout float tmax, inout HitInfo hit, inout bool didHit)
{
    float t = (po - ray.origin.y) / ray.dir.y;

    if (t < uTMin || t > tmax)
        return;

    vec3 p = ray.origin + ray.dir * t;

    if (p.x < limitsX.x || p.x > limitsX.y)
        return;
    if (p.z < limitsZ.x || p.z > limitsZ.y)
        return;

    hit.point = ray.origin + ray.dir * t;
    hit.normal = (po < ray.origin.y) ? vec3(0, 1, 0) : vec3(0, -1, 0);
    hit.t = t;

    tmax = t;

    didHit = true;
}

void IntersectRectZ(Ray ray, float po, vec2 limitsX, vec2 limitsY, inout float tmax, inout HitInfo hit, inout bool didHit)
{
    float t = (po - ray.origin.z) / ray.dir.z;

    if (t < uTMin || t > tmax)
        return;

    vec3 p = ray.origin + ray.dir * t;

    if (p.x < limitsX.x || p.x > limitsX.y)
        return;
    if (p.y < limitsY.x || p.y > limitsY.y)
        return;

    hit.point = ray.origin + ray.dir * t;
    hit.normal = (po < ray.origin.z) ? vec3(0, 0, 1) : vec3(0, 0, -1);
    hit.t = t;

    tmax = t;

    didHit = true;
}

bool IntersectAABB(Ray ray, vec3 pos, vec3 size, float tmax, inout HitInfo hit)
{
    vec3 minp = pos - size / 2.0;
    vec3 maxp = pos + size / 2.0;

    bool didHit = false;

    IntersectRectX(ray, minp.x, vec2(minp.y, maxp.y), vec2(minp.z, maxp.z), tmax, hit, didHit);
    IntersectRectX(ray, maxp.x, vec2(minp.y, maxp.y), vec2(minp.z, maxp.z), tmax, hit, didHit);
    IntersectRectY(ray, minp.y, vec2(minp.x, maxp.x), vec2(minp.z, maxp.z), tmax, hit, didHit);
    IntersectRectY(ray, maxp.y, vec2(minp.x, maxp.x), vec2(minp.z, maxp.z), tmax, hit, didHit);
    IntersectRectZ(ray, minp.z, vec2(minp.x, maxp.x), vec2(minp.y, maxp.y), tmax, hit, didHit);
    IntersectRectZ(ray, maxp.z, vec2(minp.x, maxp.x), vec2(minp.y, maxp.y), tmax, hit, didHit);

    return didHit;
}

bool IntersectWorld(Ray ray, out HitInfo hit, out vec3 color, out float reflectAmount)
{
    float tmax = 1e30;
    bool didHit = false;

    if (IntersectGroundPlane(ray, -0.5, tmax, hit))
    {
        didHit = true;
        tmax = hit.t;
        color = vec3(0.7, 0.5, 0.8);
        reflectAmount = 0.0;
    }

    for (int i = 0; i < numSpheres; i++)
    {
        if (IntersectSphere(ray, spheres[i].position, spheres[i].radius, tmax, hit))
        {
            didHit = true;
            tmax = hit.t;
            color = spheres[i].color;
            reflectAmount = spheres[i].reflectAmount;
        }
    }

    if (IntersectAABB(ray, vec3(-3, 0, -3), vec3(1.0), tmax, hit))
    {
        didHit = true;
        tmax = hit.t;
        color = vec3(0.9);
        reflectAmount = 0.0;
    }

    if (IntersectAABB(ray, vec3(-4, 1, -3), vec3(1.0, 3.0, 5.0), tmax, hit))
    {
        didHit = true;
        tmax = hit.t;
        color = vec3(0.9);
        reflectAmount = 0.0;
    }

    Triangle tri = { vec3(1,1,-1), vec3(2,2,-1), vec3(3,1,0) };
    if (IntersectTriangle(ray, tri, tmax, hit))
    {
        didHit = true;
        tmax = hit.t;
        color = vec3(0.47, 0.85, 0.06);
        reflectAmount = 0.0;
    }
    if (IntersectSphere(ray, tri.v0, 0.01, tmax, hit))
    {
        didHit = true;
        tmax = hit.t;
        color = vec3(1,0,0);
        reflectAmount = 0.0;
    }
    if (IntersectSphere(ray, tri.v1, 0.01, tmax, hit))
    {
        didHit = true;
        tmax = hit.t;
        color = vec3(1,0,0);
        reflectAmount = 0.0;
    }
    if (IntersectSphere(ray, tri.v2, 0.01, tmax, hit))
    {
        didHit = true;
        tmax = hit.t;
        color = vec3(1,0,0);
        reflectAmount = 0.0;
    }

    return didHit;
}

void ScatterRay(inout Ray ray, HitInfo hit, float reflectAmount)
{
    ray.origin = hit.point;

    vec3 diffuse = hit.normal + randInSphere();
    vec3 reflected = reflect(normalize(ray.dir), hit.normal);

    ray.dir = mix(diffuse, reflected, reflectAmount);
}

void main()
{
    randCoords = (gl_FragCoord.xy + vec2(uImageFrames) * 0.333) / vec2(uWinWidth, uWinHeight);

    vec2 uv = (gl_FragCoord.xy + randVec2() / 2.0)  / vec2(uWinWidth, uWinHeight);

    Ray ray;
    ray.origin = uRayOrigin;
    vec3 dofOffset = randInSphere() * uDOFStrength / 2.0;
    vec3 baseDir = normalize(uBotLeftRayDir + uv.x * uCamRight + uv.y * uCamUp);
    dofOffset -= dot(dofOffset, baseDir) * baseDir;
    ray.origin += dofOffset;
    vec3 rayFocusPoint = baseDir * uDOFDist + uRayOrigin;
    ray.dir = normalize(rayFocusPoint - ray.origin);

    spheres[0] = Sphere(vec3(0.0, 0.0, -1.0), 0.5, vec3(0.95), 0.0);
    spheres[1] = Sphere(vec3(1.01, 0.0, -1.0), 0.5, vec3(0.95, 0.05, 0.05), uReflectAmount);
    spheres[2] = Sphere(vec3(3.0, 0.0, -2.0), 0.5, vec3(0.95), 0.0);

    int depth = 0;

    vec3 li = vec3(1.0);

    while (depth < uMaxRayDepth)
    {
        HitInfo hit;
        vec3 color;
        float reflectAmount;

        if (IntersectWorld(ray, hit, color, reflectAmount))
        {
            li *= color;
            ScatterRay(ray, hit, reflectAmount);
        }
        else
        {
            li *= BackgroundColor(ray);
            break;
        }

        depth++;
        if (depth == uMaxRayDepth)
        {
            li = vec3(0.0);
        }
    }

    //li = vec3(ray.dir.y / 2.0 + 0.5);

    vec4 avg = imageLoad(uAvgImage, ivec2(gl_FragCoord.xy));
    li = ((avg.rgb * uImageFrames) + li) / (uImageFrames + 1);

    imageStore(uAvgImage, ivec2(gl_FragCoord.xy), vec4(li, 1.0));
    FragColor = vec4(li, 1.0);
}
