#version 440

// The wallpaper pulled along the fluid's velocity, red and blue a little more and less than green

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float warp;   // seconds of flow the picture is pulled by
    float split;  // share of the pull that red and blue differ by
};

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D field;

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 pull = texture(field, uv).xy * warp;
    vec4 color = texture(source, uv - pull);
    color.r = texture(source, uv - pull * (1.0 + split)).r;
    color.b = texture(source, uv - pull * (1.0 - split)).b;
    fragColor = color * qt_Opacity;
}
