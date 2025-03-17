#version 460
#extension GL_ARB_shading_language_include : enable
#pragma optionNV(unroll all)
#define UNROLL_LOOP
#extension GL_NV_mesh_shader : require
#extension GL_NV_gpu_shader5 : require
#extension GL_NV_bindless_texture : require
#extension GL_NV_shader_buffer_load : require

#import <nvidium:occlusion/scene.glsl>

#define ADD_SIZE (0.1f/16)

layout(local_size_x = 8) in;
layout(triangles, max_vertices=8, max_primitives=12) out;

const uint PILUTA[] = {0u, 3u, 6u, 0u, 1u, 7u, 4u, 5u};
const uint PILUTB[] = {1u, 2u, 6u, 4u, 0u, 7u, 6u, 4u};
const uint PILUTC[] = {2u, 0u, 4u, 5u, 1u, 3u, 7u, 2u};
const uint PILUTD[] = {1u, 2u, 0u, 5u, 5u, 1u, 7u, 7u};

const uint PILUTE[] = {6u, 2u, 3u, 7u};

void emitIndicies(int visIndex) {
    uint localId = gl_LocalInvocationID.x;
    gl_PrimitiveIndicesNV[(localId << 2u) | 0u] = PILUTA[localId];
    gl_PrimitiveIndicesNV[(localId << 2u) | 1u] = PILUTB[localId];
    gl_PrimitiveIndicesNV[(localId << 2u) | 2u] = PILUTC[localId];
    gl_PrimitiveIndicesNV[(localId << 2u) | 3u] = PILUTD[localId];
    gl_MeshPrimitivesNV[localId].gl_PrimitiveID = visIndex;
}

void emitParital(int visIndex) {
    uint localId = gl_LocalInvocationID.x;
    gl_PrimitiveIndicesNV[(8u * 4u) + localId] = PILUTE[localId];
    gl_MeshPrimitivesNV[localId + 8u].gl_PrimitiveID = visIndex;
    gl_PrimitiveCountNV = 12u;
}

void main() {
    Region data = regionData[regionIndicies[gl_WorkGroupID.x]];
    vec3 start = unpackRegionPosition(data) - chunkPosition.xyz - ADD_SIZE;
    vec3 end = start + 1.0 + unpackRegionSize(data) + (ADD_SIZE * 2.0);

    uint localId = gl_LocalInvocationID.x;
    vec3 corner = vec3(
    ((localId & 1u) == 0u) ? start.x : end.x,
    ((localId & 4u) == 0u) ? start.y : end.y,
    ((localId & 2u) == 0u) ? start.z : end.z
    );

    corner *= 16.0f;
    gl_MeshVerticesNV[localId].gl_Position = MVP * (getRegionTransformation(data) * vec4(corner, 1.0));

    int visibilityIndex = int(gl_WorkGroupID.x);
    regionVisibility[visibilityIndex] = uint8_t(0);

    emitIndicies(visibilityIndex);
    if (localId < 4u) {
        emitParital(visibilityIndex);
    }
}