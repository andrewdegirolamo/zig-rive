#include "rive/renderer/rive_renderer.hpp"
#include "rive/renderer/vulkan/render_context_vulkan_impl.hpp"
#include "rive/renderer/vulkan/render_target_vulkan.hpp"
#include "rive_vk_bootstrap/vulkan_device.hpp"
#include "rive_vk_bootstrap/vulkan_instance.hpp"
#include "rive_vk_bootstrap/vulkan_swapchain.hpp"
#include "riveWrapper.h"
#include <vulkan/vulkan.h>

using namespace rive;
using namespace rive::gpu;

struct Rive_VulkanImpl {
  std::unique_ptr<rive_vkb::VulkanInstance> instance;
  std::unique_ptr<rive_vkb::VulkanDevice> device;
  std::unique_ptr<RenderContext> renderContext;
  std::unique_ptr<rive_vkb::VulkanSwapchain> swapchain;
  rcp<RenderTargetVulkanImpl> renderTarget;
  VkSurfaceKHR surface = VK_NULL_HANDLE;
};

static RenderContextVulkanImpl *vulkanImpl(Rive_VulkanImpl *self) {
  return self->renderContext->static_impl_cast<RenderContextVulkanImpl>();
}

extern "C" {

Rive_VulkanImpl *rive_vulkanInit(const char *const *instance_extensions,
                                 uint32_t extension_count) {
  auto *self = new Rive_VulkanImpl();
  self->instance = rive_vkb::VulkanInstance::Create({
      .appName = "zig_rive",
      .requiredExtensions = make_span(
          const_cast<const char **>(instance_extensions), extension_count),
  });
  if (self->instance)
    self->device = rive_vkb::VulkanDevice::Create(*self->instance, {});
  if (self->device)
    self->renderContext = RenderContextVulkanImpl::MakeContext(
        self->instance->vkInstance(), self->device->vkPhysicalDevice(),
        self->device->vkDevice(), self->device->vulkanFeatures(),
        self->instance->getVkGetInstanceProcAddrPtr());
  if (!self->renderContext) {
    delete self;
    return nullptr;
  }
  return self;
}

void *rive_vulkanGetVkInstance(Rive_VulkanImpl *self) {
  return self->instance->vkInstance();
}

Rive_RenderContext *rive_vulkanGetRenderContext(Rive_VulkanImpl *self) {
  return reinterpret_cast<Rive_RenderContext *>(self->renderContext.get());
}

bool rive_vulkanInitSwapchain(Rive_VulkanImpl *self, void *vk_surface) {
  uint64_t frameNumber =
      self->swapchain ? self->swapchain->currentFrameNumber() : 0;
  self->swapchain = nullptr;
  self->surface = static_cast<VkSurfaceKHR>(vk_surface);
  self->swapchain = rive_vkb::VulkanSwapchain::Create(
      *self->instance, *self->device,
      ref_rcp(vulkanImpl(self)->vulkanContext()), self->surface,
      {
          .formatPreferences =
              {
                  {VK_FORMAT_B8G8R8A8_UNORM, VK_COLOR_SPACE_SRGB_NONLINEAR_KHR},
                  {VK_FORMAT_R8G8B8A8_UNORM, VK_COLOR_SPACE_SRGB_NONLINEAR_KHR},
              },
          .presentModePreferences = {VK_PRESENT_MODE_FIFO_KHR},
          .imageUsageFlags = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
                             VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
                             VK_IMAGE_USAGE_TRANSFER_DST_BIT,
          .initialFrameNumber = frameNumber,
      });
  if (!self->swapchain)
    return false;
  self->renderTarget = vulkanImpl(self)->makeRenderTarget(
      self->swapchain->width(), self->swapchain->height(),
      self->swapchain->imageFormat(), self->swapchain->imageUsageFlags());
  return true;
}

bool rive_vulkanBeginFrame(Rive_VulkanImpl *self, uint32_t *out_width,
                           uint32_t *out_height) {
  if (!self->swapchain)
    return false;
  if (!self->swapchain->isFrameStarted()) {
    if (self->swapchain->beginFrame() != VK_SUCCESS) {
      if (!rive_vulkanInitSwapchain(self, self->surface) ||
          self->swapchain->beginFrame() != VK_SUCCESS)
        return false;
    }
    self->renderTarget->setTargetImageView(
        self->swapchain->currentVkImageView(),
        self->swapchain->currentVkImage(),
        self->swapchain->currentLastAccess());
  }
  *out_width = self->swapchain->width();
  *out_height = self->swapchain->height();
  return true;
}

void rive_vulkanFlushAndPresent(Rive_VulkanImpl *self) {
  if (!self->swapchain)
    return;
  self->renderContext->flush({
      .renderTarget = self->renderTarget.get(),
      .externalCommandBuffer = self->swapchain->currentCommandBuffer(),
      .currentFrameNumber = self->swapchain->currentFrameNumber(),
      .safeFrameNumber = self->swapchain->safeFrameNumber(),
  });
  if (self->swapchain->endFrame(self->renderTarget->targetLastAccess()) !=
      VK_SUCCESS)
    rive_vulkanInitSwapchain(self, self->surface);
}

void rive_vulkanFree(Rive_VulkanImpl *self) {
  self->device->waitUntilIdle();
  delete self;
}
}
