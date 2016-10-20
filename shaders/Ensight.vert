#version 330 core
layout (location = 0) in vec3 position;
layout (location = 1) in uint n;

out VS_OUT {
    uint neighbors;
} vs_out;

void main()
{
    gl_Position = vec4(position,1.0);
    vs_out.neighbors = n;
}
