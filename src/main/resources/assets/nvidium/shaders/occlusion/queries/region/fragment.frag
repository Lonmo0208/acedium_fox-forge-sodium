#version 460
#extension GL_ARB_shading_language_include : enable
#pragma optionNV(unroll all)
#define UNROLL_LOOP
#extension GL_NV_gpu_shader5 : require
#extension GL_NV_bindless_texture : require
#extension GL_NV_shader_buffer_load : require

#import <nvidium:occlusion/scene.glsl>
layout(early_fragment_tests) in;

#ifdef DEBUG
layout(location = 0) out vec4 colour;
void main() {
    uint uid = gl_PrimitiveID*132471u + 123571u;
    colour = vec4(
    float((uid >> 0u) & 7u) / 7.0,
    float((uid >> 3u) & 7u) / 7.0,
    float((uid >> 6u) & 7u) / 7.0,
    1.0
    );
    regionVisibility[gl_PrimitiveID] = uint8_t(1);
}
#else
void main() {
    regionVisibility[gl_PrimitiveID] = uint8_t(1);
}
#endif