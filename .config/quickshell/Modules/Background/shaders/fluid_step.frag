#version 440

// One step of a cheap velocity field: self-advection, a little diffusion, decay, and the cursor
// pushing and swirling it. Velocity is in uv per second, in rg. A step with dt 0 passes the field
// on unchanged.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float dt;
    float decay;     // per second
    float diffusion; // share mixed with the neighbours, per second
    float aspect;    // width / height
    float radius;    // of the push, in screen heights
    float swirl;     // share of the push turned around the cursor
    vec2 texel;
    vec2 cursor;     // uv
    vec2 push;       // uv per second
};

layout(binding = 1) uniform sampler2D field;

vec2 velocity(vec2 p) {
    return texture(field, p).xy;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 v = velocity(uv - dt * velocity(uv));
    vec2 around = 0.25 * (velocity(uv + vec2(texel.x, 0.0)) + velocity(uv - vec2(texel.x, 0.0)) + velocity(uv + vec2(0.0, texel.y)) + velocity(uv - vec2(0.0, texel.y)));
    v = mix(v, around, diffusion * dt) * exp(-decay * dt);

    vec2 d = (uv - cursor) * vec2(aspect, 1.0);
    float reach = exp(-dot(d, d) / (radius * radius));
    // The speed in screen heights, so a move in x swirls as much as one in y on any monitor
    vec2 tangent = vec2(-d.y, d.x) / max(length(d), 1e-4);
    vec2 turn = swirl * length(push * vec2(aspect, 1.0)) * tangent / vec2(aspect, 1.0);
    v += (push + turn) * reach * dt * 60.0;

    fragColor = vec4(v, 0.0, 1.0);
}
