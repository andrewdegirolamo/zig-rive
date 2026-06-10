#import "rive/renderer/metal/render_context_metal_impl.h"
#import "riveWrapper.h"
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#include <cstdint>

using namespace rive::gpu;

id<MTLDevice> device = MTLCreateSystemDefaultDevice();

// --rive::renderContext Metal

extern "C" {

Rive_RenderContext *rive_MakeContextMetal(void *mtl_device) {
  id<MTLDevice> m_gpu = static_cast<id<MTLDevice>>(mtl_device);

  // TODO: expose contextOptions

  RenderContextMetalImpl::ContextOptions m_opts;

  return reinterpret_cast<Rive_RenderContext *>(
      rive::gpu::RenderContextMetalImpl::MakeContext(m_gpu, m_opts).release());
}

Rive_RenderTargetMetal *rive_getMetalRenderTarget(Rive_RenderContext *context,
                                                  uint32_t width,
                                                  uint32_t height) {
  if (!context)
    return nullptr;
  auto *cpp_context = reinterpret_cast<rive::gpu::RenderContext *>(context);
  auto *renderContextImpl =
      cpp_context->static_impl_cast<rive::gpu::RenderContextMetalImpl>();
  return reinterpret_cast<Rive_RenderTargetMetal *>(
      renderContextImpl
          // TODO: expose format
          ->makeRenderTarget(MTLPixelFormatBGRA8Unorm, width, height)
          .release());
}

void rive_setMetalTargetTexture(Rive_RenderTargetMetal *target, void *texture) {
  auto *cpp_target = reinterpret_cast<rive::gpu::RenderTargetMetal *>(target);
  auto obj_texture = (__bridge id<MTLTexture>)texture;
  cpp_target->setTargetTexture(obj_texture);
}
}
