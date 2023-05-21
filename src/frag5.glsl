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

const vec3 vertices[] = {
    vec3(-1.000000,-1.000000,1.000000),
    vec3(-0.367586,1.601401,0.772464),
    vec3(-1.000000,-1.000000,-1.000000),
    vec3(-0.250707,1.690726,-0.772464),
    vec3(1.000000,-1.000000,1.000000),
    vec3(0.367586,1.601401,0.772464),
    vec3(1.000000,-1.000000,-1.000000),
    vec3(0.250707,1.690726,-0.772464),
    vec3(-1.000000,1.000000,1.000000),
    vec3(-1.000000,1.000000,-1.000000),
    vec3(1.000000,1.000000,-1.000000),
    vec3(1.000000,1.000000,1.000000),
    vec3(-0.367586,2.190278,0.772464),
    vec3(-0.250707,2.111364,-0.772464),
    vec3(0.250707,2.111364,-0.772464),
    vec3(0.367586,2.190278,0.772464),
    vec3(-0.632554,2.266388,0.632554),
    vec3(-0.632554,2.266388,-0.632554),
    vec3(0.632554,2.266388,-0.632554),
    vec3(0.632554,2.266388,0.632554),
    vec3(-0.772464,2.266388,0.772464),
    vec3(0.772464,2.266388,-0.772464),
    vec3(0.772464,2.266388,0.772464),
    vec3(-0.632554,3.360695,0.632554),
    vec3(-0.632554,3.360695,-0.632554),
    vec3(0.632554,3.360695,-0.632554),
    vec3(0.632554,3.360695,0.632554),
    vec3(0.632554,2.723043,-0.459706),
    vec3(0.632554,2.723043,0.459706),
    vec3(-0.632554,2.688775,0.632554),
    vec3(-0.632554,2.688775,-0.632554),
    vec3(0.632554,2.892093,-0.459706),
    vec3(-0.632554,2.926362,0.632554),
    vec3(0.632554,2.892093,0.459706),
    vec3(-0.632554,2.926362,-0.632554),
    vec3(0.632554,2.926362,0.632554),
    vec3(0.632554,2.688775,0.632554),
    vec3(0.632554,2.688775,-0.632554),
    vec3(0.632554,2.926362,-0.632554),
    vec3(0.797520,2.892093,0.459706),
    vec3(0.797520,2.723043,0.459706),
    vec3(0.797520,2.723043,-0.459706),
    vec3(0.797520,2.892093,-0.459706),
    vec3(-0.772464,1.000000,-0.772464),
    vec3(0.772464,1.000000,-0.772464),
    vec3(-0.772464,2.266388,-0.772464),
    vec3(-0.250707,1.697111,-1.012442),
    vec3(0.250707,1.697111,-1.012442),
    vec3(-0.250707,2.104979,-0.909582),
    vec3(0.250707,2.104979,-0.909582),
    vec3(-0.413806,1.600969,-1.190748),
    vec3(0.413806,1.600969,-1.190748),
    vec3(-0.413806,2.274179,-1.020973),
    vec3(0.413806,2.274179,-1.020973),
    vec3(-0.498919,1.816561,-2.266864),
    vec3(0.498919,1.816561,-2.266864),
    vec3(-0.498919,2.536431,-1.839653),
    vec3(0.498919,2.536431,-1.839653),
    vec3(-0.200061,2.382759,-2.392013),
    vec3(0.200061,2.382759,-2.392013),
    vec3(-0.200061,2.605918,-2.141274),
    vec3(0.200061,2.605918,-2.141274),
    vec3(-0.060075,2.407755,-1.953894),
    vec3(-0.060075,3.158218,-1.953894),
    vec3(-0.060075,2.407755,-2.046106),
    vec3(-0.060075,3.158218,-2.046106),
    vec3(0.060075,2.407755,-1.953894),
    vec3(0.060075,3.158218,-1.953894),
    vec3(0.060075,2.407755,-2.046106),
    vec3(0.060075,3.158218,-2.046106),
    vec3(-0.060075,2.483619,-2.060631),
    vec3(-0.060075,3.129342,-2.443040),
    vec3(-0.060075,2.436631,-2.139974),
    vec3(-0.060075,3.082354,-2.522382),
    vec3(0.060075,2.483619,-2.060631),
    vec3(0.060075,3.129342,-2.443040),
    vec3(0.060075,2.436631,-2.139974),
    vec3(0.060075,3.082354,-2.522382),
    vec3(-0.060075,2.350282,-2.233390),
    vec3(-0.060075,2.835204,-2.806142),
    vec3(-0.060075,2.279906,-2.292974),
    vec3(-0.060075,2.764828,-2.865726),
    vec3(0.060075,2.350282,-2.233390),
    vec3(0.060075,2.835204,-2.806142),
    vec3(0.060075,2.279906,-2.292974),
    vec3(0.060075,2.764828,-2.865726),
    vec3(0.772464,1.000000,0.772464),
    vec3(-0.772464,1.000000,0.772464),
    vec3(0.367586,1.601401,0.853107),
    vec3(-0.367586,1.601401,0.853107),
    vec3(0.367586,2.190278,0.853107),
    vec3(-0.367586,2.190278,0.853107),
    vec3(0.433731,1.548419,1.108736),
    vec3(-0.433731,1.548419,1.108736),
    vec3(0.433731,2.243260,1.108736),
    vec3(-0.433731,2.243260,1.108736),
    vec3(0.536695,1.565082,1.448367),
    vec3(-0.536695,1.565082,1.448367),
    vec3(0.299083,2.226597,1.997584),
    vec3(-0.299083,2.226597,1.997584),
    vec3(0.261131,1.278349,1.709279),
    vec3(-0.261131,1.278349,1.709279),
    vec3(0.221596,1.286733,2.127530),
    vec3(-0.221596,1.286733,2.127530),
    vec3(0.133144,0.490561,1.827611),
    vec3(-0.133144,0.490561,1.827611),
    vec3(0.133144,0.494837,2.040866),
    vec3(-0.133144,0.494837,2.040866),
};

const int indicies[] = {
    9,3,1,
    10,7,3,
    11,5,7,
    12,1,5,
    7,1,3,
    2,92,13,
    44,9,88,
    45,10,44,
    87,11,45,
    88,12,87,
    8,50,15,
    45,23,87,
    88,46,44,
    39,27,36,
    18,21,17,
    19,46,18,
    20,22,19,
    17,23,20,
    25,27,26,
    33,25,35,
    36,24,33,
    35,26,39,
    18,38,19,
    20,30,17,
    17,31,18,
    19,37,20,
    31,39,38,
    37,33,30,
    30,35,31,
    34,43,32,
    34,37,29,
    29,38,28,
    28,39,32,
    32,36,34,
    42,40,41,
    28,41,29,
    32,42,28,
    29,40,34,
    8,44,4,
    14,22,15,
    4,46,14,
    8,22,45,
    49,51,47,
    15,49,14,
    4,49,47,
    4,48,8,
    51,56,52,
    47,52,48,
    50,52,54,
    50,53,49,
    58,60,62,
    52,58,54,
    54,57,53,
    51,57,55,
    59,62,60,
    58,61,57,
    57,59,55,
    55,60,56,
    64,65,63,
    66,69,65,
    70,67,69,
    68,63,67,
    69,63,65,
    66,68,70,
    72,73,71,
    74,77,73,
    77,76,75,
    76,71,75,
    77,71,73,
    74,76,78,
    79,82,81,
    82,85,81,
    86,83,85,
    84,79,83,
    85,79,81,
    82,84,86,
    2,87,6,
    16,21,13,
    6,23,16,
    2,21,88,
    91,93,89,
    13,91,16,
    16,89,6,
    6,90,2,
    95,97,93,
    89,94,90,
    90,96,92,
    92,95,91,
    100,102,104,
    93,98,94,
    96,98,100,
    96,99,95,
    103,105,101,
    100,103,99,
    99,101,97,
    97,102,98,
    105,108,106,
    101,106,102,
    104,106,108,
    104,107,103,
    9,10,3,
    10,11,7,
    11,12,5,
    12,9,1,
    7,5,1,
    2,90,92,
    44,10,9,
    45,11,10,
    87,12,11,
    88,9,12,
    8,48,50,
    45,22,23,
    88,21,46,
    39,26,27,
    18,46,21,
    19,22,46,
    20,23,22,
    17,21,23,
    25,24,27,
    33,24,25,
    36,27,24,
    35,25,26,
    18,31,38,
    20,37,30,
    17,30,31,
    19,38,37,
    31,35,39,
    37,36,33,
    30,33,35,
    34,40,43,
    34,36,37,
    29,37,38,
    28,38,39,
    32,39,36,
    42,43,40,
    28,42,41,
    32,43,42,
    29,41,40,
    8,45,44,
    14,46,22,
    4,44,46,
    8,15,22,
    49,53,51,
    15,50,49,
    4,14,49,
    4,47,48,
    51,55,56,
    47,51,52,
    50,48,52,
    50,54,53,
    58,56,60,
    52,56,58,
    54,58,57,
    51,53,57,
    59,61,62,
    58,62,61,
    57,61,59,
    55,59,60,
    64,66,65,
    66,70,69,
    70,68,67,
    68,64,63,
    69,67,63,
    66,64,68,
    72,74,73,
    74,78,77,
    77,78,76,
    76,72,71,
    77,75,71,
    74,72,76,
    79,80,82,
    82,86,85,
    86,84,83,
    84,80,79,
    85,83,79,
    82,80,84,
    2,88,87,
    16,23,21,
    6,87,23,
    2,13,21,
    91,95,93,
    13,92,91,
    16,91,89,
    6,89,90,
    95,99,97,
    89,93,94,
    90,94,96,
    92,96,95,
    100,98,102,
    93,97,98,
    96,94,98,
    96,100,99,
    103,107,105,
    100,104,103,
    99,103,101,
    97,101,102,
    105,107,108,
    101,105,106,
    104,102,106,
    104,108,107,
};


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

bool IntersectTriangle(Ray ray, vec3 v0, vec3 v1, vec3 v2, float tmax, inout HitInfo hit)
{
    // https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-rendering-a-triangle/moller-trumbore-ray-triangle-intersection.html

    vec3 edge1 = v1 - v0;
    vec3 edge2 = v2 - v0;

    vec3 a = cross(ray.dir, edge2);
    float det = dot(edge1, a);

    if (det < 0.0001)
        return false;

    float invDet = 1.0 / det;

    vec3 tvec = ray.origin - v0;
    float u = dot(tvec, a) * invDet;
    if (u < 0.0 || u > 1.0)
        return false;

    vec3 qvec = cross(tvec, edge1);
    float v = dot(qvec, ray.dir) * invDet;
    if (v < 0.0 || u + v > 1.0)
        return false;

    float t = dot(qvec, edge2) * invDet;

    if (t < uTMin || t > tmax)
        return false;

    hit.point = ray.origin + ray.dir * t;
    hit.normal = normalize(cross(edge1, edge2));
    hit.t = t;

    return true;
}

bool IntersectWorld(Ray ray, out HitInfo hit, out vec3 color, out float reflectAmount)
{
    float tmax = 1e30;
    bool didHit = false;

    if (IntersectSphere(ray, vec3(0.0, -100.8, -1.0), 100.0, tmax, hit))
    {
        didHit = true;
        tmax = hit.t;
        color = vec3(0.8);
        reflectAmount = 0.0;
    }

    for (int i = 0; i < indicies.length() - 2; i += 3)
    {
        vec3 v0 = vertices[indicies[i] - 1];
        vec3 v1 = vertices[indicies[i + 1] - 1];
        vec3 v2 = vertices[indicies[i + 2] - 1];

        if (IntersectTriangle(ray, v0, v1, v2, tmax, hit))
        {
            didHit = true;
            tmax = hit.t;
            color = vec3(0.9, 0.1, 0.1);
            reflectAmount = uReflectAmount;
        }
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

    vec4 avg = imageLoad(uAvgImage, ivec2(gl_FragCoord.xy));
    li = ((avg.rgb * uImageFrames) + li) / (uImageFrames + 1);

    imageStore(uAvgImage, ivec2(gl_FragCoord.xy), vec4(li, 1.0));
    FragColor = vec4(li, 1.0);
}
