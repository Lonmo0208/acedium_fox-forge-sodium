package me.cortex.nvidium.mixin.sodium;

import dev.architectury.patchedmixin.staticmixin.spongepowered.asm.mixin.Shadow;
import me.cortex.nvidium.NvidiumWorldRenderer;
import me.cortex.nvidium.sodiumCompat.INvidiumWorldRendererSetter;
import me.jellysquid.mods.sodium.client.gl.device.CommandList;
import me.jellysquid.mods.sodium.client.render.chunk.compile.ChunkBuildOutput;
import me.jellysquid.mods.sodium.client.render.chunk.region.RenderRegion;
import me.jellysquid.mods.sodium.client.render.chunk.region.RenderRegionManager;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Unique;

import java.util.Collection;

@Mixin(value = RenderRegionManager.class, remap = false)
public abstract class MixinRenderRegionManager implements INvidiumWorldRendererSetter {


    @Shadow
    protected abstract void uploadMeshes(CommandList commandList, RenderRegion region, Collection<ChunkBuildOutput> results);

    @Unique private NvidiumWorldRenderer renderer;



    @Override
    public void setWorldRenderer(NvidiumWorldRenderer renderer) {
        this.renderer = renderer;
    }

    public NvidiumWorldRenderer getRenderer() {
        return renderer;
    }
}
