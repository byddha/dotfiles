#version 440
// CRT Scanlines - animated

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 tex = texture(source, uv);

    // Slow scrolling scanlines
    float scanY = uv.y + time * 0.02;
    float scanline = sin(scanY * 600.0) * 0.5 + 0.5;
    scanline = pow(scanline, 1.2) * 0.25 + 0.75;

    // Brighter scan bar that moves down
    float scanBar = smoothstep(0.0, 0.02, fract(time * 0.1) - uv.y + 0.02);
    scanBar *= smoothstep(0.04, 0.02, fract(time * 0.1) - uv.y + 0.02);

    // Flicker
    float flicker = 0.95 + 0.05 * sin(time * 12.0);

    // RGB shift
    float shift = 0.0015;
    float r = texture(source, uv + vec2(shift, 0.0)).r;
    float g = tex.g;
    float b = texture(source, uv - vec2(shift, 0.0)).b;

    vec3 result = vec3(r, g, b) * scanline * flicker;

    // Add scan bar brightness
    result += result * scanBar * 0.3;

    // Vignette
    vec2 vigUV = uv * (1.0 - uv);
    float vig = pow(vigUV.x * vigUV.y * 15.0, 0.25);
    result *= vig;

    fragColor = vec4(result, tex.a) * qt_Opacity;
}
