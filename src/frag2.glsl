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
};

const int numSpheres = 3;
Sphere spheres[numSpheres];

vec2 randCoords;

float rand()
{
    randCoords *= 1.5;
    return fract(sin(dot(randCoords, vec2(12.9898, 78.233))) * 43758.5453);
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
        if (length(r) <= 1.0)
            return r;
    }
    return vec3(0.0);
}

vec3 BackgroundColor(Ray ray)
{
    float y = ray.dir.y;
    y = y / 2.0 + 0.5;

    vec3 bottomColor = vec3(0.8, 0.9, 1.0);
    vec3 topColor = vec3(0.35, 0.7, 1.0);

    return mix(bottomColor, topColor, y);
}

bool IntersectSphere(Ray ray, vec3 center, float radius, float tmax, out HitInfo hit)
{
    vec3 oc = ray.origin - center;

    float a = dot(ray.dir, ray.dir);
    float b = 2 * dot(ray.dir, oc);
    float c = dot(oc, oc) - radius * radius;

    float D = b * b - 4 * a * c;
    if (D < 0.0) return false;

    float sqrtD = sqrt(D);
    
    float x = (-b - sqrtD) / (2 * a);
    if (x < uTMin || x > tmax)
    {
        x = (-b + sqrtD) / (2 * a);
        if (x < uTMin || x > tmax)
            return false;
    }

    hit.point = ray.origin + ray.dir * x;
    hit.normal = normalize(hit.point - center);
    hit.t = x;

    return true;
}

bool IntersectWorld(Ray ray, out HitInfo hit)
{
    float tmax = 1e30f;
    bool didHit = false;

    for (int i = 0; i < numSpheres; i++)
    {
        if (IntersectSphere(ray, spheres[i].position, spheres[i].radius, tmax, hit))
        {
            didHit = true;
            tmax = hit.t;
        }
    }

    return didHit;
}

void ReflectRay(inout Ray ray, HitInfo hit, float fuzz)
{
    ray.origin = hit.point;
    ray.dir = reflect(normalize(ray.dir), hit.normal);
    ray.dir += randInSphere() * fuzz;
}

void main()
{
    vec2 uv = gl_FragCoord.xy / vec2(uWinWidth, uWinHeight);

    randCoords = gl_FragCoord.xy;

    Ray ray;
    ray.origin = uRayOrigin;
    ray.dir = uBotLeftRayDir + uv.x * uCamRight + uv.y * uCamUp;

    spheres[0] = Sphere(vec3(0.0, 0.0, -1.0), 0.5);
    spheres[1] = Sphere(vec3(0.0, -100.5, -1.0), 100.0);
    spheres[2] = Sphere(vec3(1.0, 0.0, -1.0), 0.5);

    int depth = 0;

    vec3 li = vec3(1.0);

    while (depth < uMaxRayDepth)
    {
        HitInfo hit;
        if (IntersectWorld(ray, hit))
        {
            li *= vec3(0.9);
            ReflectRay(ray, hit, 0.0);
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


    FragColor = vec4(li, 1.0);
}
