#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // Pack floats together
    float overlayOpacity;
    float hatchOpacity;
    float hatchSpacing;
    // vec4s are 16-byte aligned
    vec4 overlayColor;
    vec4 hatchColor;
    vec4 selection;
    // Pack resolution and cornerRadius together
    vec4 resolutionAndRadius;  // xy = resolution, z = cornerRadius
    // Cutout regions for floating windows (up to 4)
    vec4 cutout1;  // x, y, width, height (0,0,0,0 = disabled)
    vec4 cutout2;
    vec4 cutout3;
    vec4 cutout4;
};

#define resolution resolutionAndRadius.xy
#define cornerRadius resolutionAndRadius.z

// Signed distance to rounded box (negative inside, positive outside)
float roundedBoxSDF(vec2 p, vec2 size, float radius) {
    vec2 q = abs(p) - size + radius;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

// Check if point is inside a cutout region (returns true if inside)
bool inCutout(vec2 p, vec4 cutout) {
    // Skip if cutout is disabled (zero size)
    if (cutout.z <= 0.0 || cutout.w <= 0.0) return false;
    return p.x >= cutout.x && p.x <= cutout.x + cutout.z &&
           p.y >= cutout.y && p.y <= cutout.y + cutout.w;
}

void main() {
    vec2 fragCoord = qt_TexCoord0 * resolution;

    // Rounded corner mask using SDF
    vec2 center = resolution * 0.5;
    float dist = roundedBoxSDF(fragCoord - center, center, cornerRadius);
    if (dist > 0.0) {
        fragColor = vec4(0.0);
        return;
    }
    // Anti-alias the edge
    float cornerAA = 1.0 - smoothstep(-1.0, 0.0, dist);

    // Check if inside selection rectangle
    bool inSelection = fragCoord.x >= selection.x &&
                       fragCoord.x <= selection.x + selection.z &&
                       fragCoord.y >= selection.y &&
                       fragCoord.y <= selection.y + selection.w;

    if (inSelection) {
        fragColor = vec4(0.0);
        return;
    }

    // Check if inside any floating window cutout region
    if (inCutout(fragCoord, cutout1) || inCutout(fragCoord, cutout2) ||
        inCutout(fragCoord, cutout3) || inCutout(fragCoord, cutout4)) {
        fragColor = vec4(0.0);
        return;
    }

    // Dark overlay
    vec4 overlay = vec4(overlayColor.rgb, overlayOpacity);

    // Diagonal hatching - distance-based anti-aliasing (top-left to bottom-right)
    float diagonal = fragCoord.x - fragCoord.y;

    // Distance to nearest line (centered mod)
    float d = mod(diagonal, hatchSpacing);
    float distToLine = min(d, hatchSpacing - d);

    // Sharp 1px line with slight AA
    float hatch = 1.0 - smoothstep(0.0, 0.7, distToLine);

    vec4 hatchLayer = vec4(hatchColor.rgb, hatch * hatchOpacity);

    // Simple alpha blend
    float outAlpha = overlay.a + hatchLayer.a * (1.0 - overlay.a);
    vec3 outRgb = (overlay.rgb * overlay.a + hatchLayer.rgb * hatchLayer.a * (1.0 - overlay.a)) / max(outAlpha, 0.001);

    fragColor = vec4(outRgb, outAlpha * cornerAA) * qt_Opacity;
}
