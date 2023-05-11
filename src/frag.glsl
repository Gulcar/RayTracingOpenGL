#version 330 core

out vec4 FragColor;

uniform float uWinWidth;
uniform float uWinHeight;
uniform vec3 uBotLeftRayDir;
uniform vec3 uCamRight;
uniform vec3 uCamUp;
uniform vec3 uRayOrigin;

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
    if (x < 0.001f || x > tmax)
    {
        x = (-b + sqrtD) / (2 * a);
        if (x < 0.001f || x > tmax)
            return false;
    }

    hit.point = ray.origin + ray.dir * x;
    hit.normal = normalize(hit.point - center);
    hit.t = x;

    return true;
}

void main()
{
    vec2 uv = gl_FragCoord.xy / vec2(uWinWidth, uWinHeight);

    Ray ray;
    ray.origin = uRayOrigin;
    ray.dir = uBotLeftRayDir + uv.x * uCamRight + uv.y * uCamUp - uRayOrigin;

    HitInfo hit;
    if (IntersectSphere(ray, vec3(0.0, 0.0, -1.0), 0.5, 1e30f, hit))
    {
        FragColor = vec4(hit.normal / 2.0 + vec3(0.5), 1.0);
        return;
    }

    FragColor = vec4(BackgroundColor(ray), 1.0);
}
