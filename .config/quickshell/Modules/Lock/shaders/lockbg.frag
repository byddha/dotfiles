#version 440

// Lock screen background: duotone color mapping + halftone-dot corner overlay
// + film grain + vignette. Wallpaper is recolored using two theme colors.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 darkColor;
    vec4 lightColor;
    float gamma;
    float grainStrength;
    float vignetteStrength;
    float halftoneEdge;
    float halftoneCellSize;
    float halftoneStrength;
    vec2 resolution;
};

layout(binding = 1) uniform sampler2D source;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 tex = texture(source, uv);

    // Luminance → gamma → duotone map
    float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
    lum = pow(clamp(lum, 0.0, 1.0), gamma);
    vec3 smoothMapped = mix(darkColor.rgb, lightColor.rgb, lum);

    // Halftone dot pattern (luminance-sized dots)
    vec2 fragCoord = uv * resolution;
    vec2 cell = mod(fragCoord, halftoneCellSize) - halftoneCellSize * 0.5;
    float dotRadius = halftoneCellSize * 0.5 * sqrt(lum);
    float dotMask = 1.0 - smoothstep(dotRadius - 1.0, dotRadius + 1.0, length(cell));
    vec3 dotMapped = mix(darkColor.rgb, lightColor.rgb, dotMask);

    // Subtle radial blend: dots fade in toward corners
    vec2 vUV = uv - 0.5;
    float distFromCenter = length(vUV) * 1.414;
    float halftoneAmount = smoothstep(halftoneEdge, 1.2, distFromCenter) * 0.45 * halftoneStrength;

    vec3 mapped = mix(smoothMapped, dotMapped, halftoneAmount);

    // Vignette
    float vig = smoothstep(0.85, 0.2, length(vUV));
    mapped *= mix(1.0, vig, vignetteStrength);

    // Film grain
    mapped += (hash(uv * 1024.0) - 0.5) * grainStrength;

    fragColor = vec4(mapped, tex.a) * qt_Opacity;
}
