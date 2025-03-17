#version 460
#extension GL_ARB_shading_language_include : enable
#pragma optionNV(unroll all)
#define UNROLL_LOOP
#extension GL_NV_mesh_shader : require
#extension GL_NV_gpu_shader5 : require
#extension GL_NV_bindless_texture : require
#extension GL_KHR_shader_subgroup_basic : require
#extension GL_KHR_shader_subgroup_ballot : require
#extension GL_KHR_shader_subgroup_vote : require

#import <nvidium:occlusion/scene.glsl>

#define ADD_SIZE (0.1f)
layout(local_size_x = 8) in;
layout(triangles, max_vertices=8, max_primitives=12) out;

taskNV in Task {
    uint _visOutBase;
    uint _offset;
    mat4 regionTransform;
};

const uint PILUTA[] = {0u, 3u, 6u, 0u, 1u, 7u, 4u, 5u};
const uint PILUTB[] = {1u, 2u, 6u, 4u, 0u, 7u, 6u, 4u};
const uint PILUTC[] = {2u, 0u, 4u, 5u, 1u, 3u, 7u, 2u};
const uint PILUTD[] = {1u, 2u, 0u, 5u, 5u, 1u, 7u, 7u};
const uint PILUTE[] = {6u, 2u, 3u, 7u};

void emitIndicies(int visIndex) {
    uint lid = gl_LocalInvocationID.x;
    gl_PrimitiveIndicesNV[(lid << 2u) | 0u] = PILUTA[lid];
    gl_PrimitiveIndicesNV[(lid << 2u) | 1u] = PILUTB[lid];
    gl_PrimitiveIndicesNV[(lid << 2u) | 2u] = PILUTC[lid];
    gl_PrimitiveIndicesNV[(lid << 2u) | 3u] = PILUTD[lid];
    gl_MeshPrimitivesNV[lid].gl_PrimitiveID = visIndex;
}

void emitParital(int visIndex) {
    uint lid = gl_LocalInvocationID.x;
    gl_PrimitiveIndicesNV[(8u * 4u) + lid] = PILUTE[lid];
    gl_MeshPrimitivesNV[lid + 8u].gl_PrimitiveID = visIndex;
}

void main() {
    uint visibilityIndex = _visOutBase | gl_WorkGroupID.x;
    uint8_t lastData = sectionVisibility[visibilityIndex];

    ivec4 header = sectionData[_offset | gl_WorkGroupID.x].header;
    if (sectionEmpty(header) || ((header.y & int(1u << 17u)) != 0)) {
        if (gl_LocalInvocationID.x == 0u) {
            sectionVisibility[visibilityIndex] = uint8_t(0u);
            gl_PrimitiveCountNV = 0u;
        }
        return;
    }

    uvec3 headerUint = uvec3(header.xyz);
    vec3 mins = vec3(headerUint & 0xFu) - ADD_SIZE;
    vec3 maxs = mins + vec3((headerUint >> 4u) & 0xFu) + 1.0f + (ADD_SIZE * 2.0f);

    ivec3 chunk = ivec3(headerUint >> 8u);
    chunk.y = int((uint(chunk.y) & 0x1ffu) << (32u - 9u)) >> (32u - 9u);

    ivec3 relativeChunkPos = chunk - chunkPosition.xyz;
    vec3 corner = vec3(relativeChunkPos << 4);
    vec3 cornerCopy = corner;

    uint lid = gl_LocalInvocationID.x;
    corner += vec3(
    ((lid & 1u) == 0u) ? mins.x : maxs.x,
    ((lid & 4u) == 0u) ? mins.y : maxs.y,
    ((lid & 2u) == 0u) ? mins.z : maxs.z
    );
    gl_MeshVerticesNV[lid].gl_Position = MVP * (regionTransform * vec4(corner, 1.0));

    int prim_payload = ((int(visibilityIndex) << 8) | ((int(uint(lastData)) << 1) & 0xff)) | 1;

    emitIndicies(prim_payload);
    if (lid < 4u) {
        emitParital(prim_payload);
    }
    if (lid == 0u) {
        cornerCopy += subchunkOffset.xyz;
        vec3 minPos = mins + cornerCopy;
        vec3 maxPos = maxs + cornerCopy;
        bool isInSection = all(lessThan(minPos, vec3(ADD_SIZE))) && all(lessThan(vec3(-ADD_SIZE), maxPos));
        sectionVisibility[visibilityIndex] = uint8_t((uint(lastData) << 1u) | uint(isInSection));
        gl_PrimitiveCountNV = 12u;
    }
}