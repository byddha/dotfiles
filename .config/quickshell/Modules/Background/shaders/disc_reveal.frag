#version 440

// Shows the source inside a disc that grows from center until it covers the whole item, with a
// soft edge as wide as DankMaterialShell's. Distances are in units of the item's height, so the
// disc stays round.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;  // 0 nothing shown, 1 all shown
    float aspect;    // item width / height
    vec2 center;     // in the item, 0..1
};

layout(binding = 1) uniform sampler2D source;

const float edge = 0.03;

void main() {
    vec2 p = vec2(qt_TexCoord0.x * aspect, qt_TexCoord0.y);
    vec2 c = vec2(center.x * aspect, center.y);
    float farthest = length(vec2(max(c.x, aspect - c.x), max(c.y, 1.0 - c.y)));
    // The edge starts outside the item and ends past the farthest corner, so 0 and 1 are exact
    float radius = progress * (farthest + edge);
    float inside = 1.0 - smoothstep(radius - edge, radius, distance(p, c));
    fragColor = texture(source, qt_TexCoord0) * inside * qt_Opacity;
}
