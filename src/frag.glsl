#version 330 core

out vec4 FragColor;

void main()
{
    vec2 uv = gl_FragCoord.xy / vec2(1600,900);
    FragColor = vec4(uv.xy, 0.1, 1.0);
}

