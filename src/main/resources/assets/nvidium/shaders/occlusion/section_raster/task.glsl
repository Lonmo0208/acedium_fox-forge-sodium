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

layout(local_size_x=1) in;

taskNV out Task {
    uint _visOutBase;
    uint _offset;
    mat4 regionTransform;
};

void main() {
    uint cmdIdx = gl_WorkGroupID.x;
    uint transCmdIdx = (uint(regionCount) - gl_WorkGroupID.x) - 1u;

    if (regionVisibility[gl_WorkGroupID.x] == uint8_t(0u)) {
        terrainCommandBuffer[cmdIdx] = uvec2(0u);
        translucencyCommandBuffer[transCmdIdx] = uvec2(0u);
        gl_TaskCountNV = 0u;
        return;
    }

    #ifdef STATISTICS_REGIONS
    atomicAdd(statistics_buffer, 1u);
    #endif

    uint32_t offset = uint32_t(regionIndicies[gl_WorkGroupID.x]);
    Region data = regionData[offset];
    int count = unpackRegionCount(data) + 1;

    _visOutBase = offset << 8u;
    _offset = offset << 8u;
    regionTransform = getRegionTransformation(data);

    gl_TaskCountNV = uint(count);

    terrainCommandBuffer[cmdIdx] = uvec2(uint(count), _visOutBase);
    translucencyCommandBuffer[transCmdIdx] = uvec2(uint(count), _visOutBase);
}