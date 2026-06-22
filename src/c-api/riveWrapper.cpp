#include "rive/animation/state_machine_instance.hpp"
#include "rive/artboard.hpp"
#include "rive/factory.hpp"
#include "rive/file.hpp"
#include "rive/math/mat2d.hpp"
#include "rive/refcnt.hpp"
#include "rive/renderer/render_context.hpp"
#include "rive/renderer/render_target.hpp"
#include "rive/renderer/rive_renderer.hpp"
#include "rive/span.hpp"
#include "rive/viewmodel/runtime/viewmodel_instance_list_runtime.hpp"
#include "rive/viewmodel/runtime/viewmodel_instance_runtime.hpp"
#include "rive/viewmodel/runtime/viewmodel_runtime.hpp"
#include "rive/viewmodel/viewmodel_instance.hpp"
#include "rive/viewmodel/viewmodel_instance_boolean.hpp"
#include "rive/viewmodel/viewmodel_instance_color.hpp"
#include "rive/viewmodel/viewmodel_instance_enum.hpp"
#include "rive/viewmodel/viewmodel_instance_number.hpp"
#include "rive/viewmodel/viewmodel_instance_trigger.hpp"
#include "rive/viewmodel/viewmodel_instance_value.hpp"
#include "utils/no_op_factory.hpp"
#include <cstddef>
#include <cstdint>
#include <memory>
#include <sys/types.h>

#include "riveWrapper.h"


struct Rive_File : public rive::File {

  using rive::File::import;
};

// TODO: Can I put everything in header file?
// TODO: Figure out memory management

extern "C" {

//
Rive_File *rive_file_import(const uint8_t *data, size_t size,
                            Rive_Factory *factory,
                            Rive_ImportResult *out_result) {

  rive::Span<const uint8_t> data_span(data, size);
  rive::Factory *cpp_factory = reinterpret_cast<rive::Factory *>(factory);
  rive::ImportResult cpp_result;

  // rive::file

  rive::rcp<rive::File> file =
      rive::File::import(data_span, cpp_factory, &cpp_result);

  if (out_result) {
    *out_result = static_cast<Rive_ImportResult>(cpp_result);
  }
  if (!file || cpp_result != rive::ImportResult::success) {
    return nullptr;
  }

  // unwrap from rcp
  return reinterpret_cast<Rive_File *>(file.release());
}

void rive_file_release(Rive_File *file) {
  if (file) {

    // rewrap into rcp
    // rive::rcp<rive::File> file_to_clean(reinterpret_cast<rive::File*>(file));
    reinterpret_cast<rive::File *>(file)->unref();
  }
}

Rive_ArtboardInstance *rive_file_artboardDefault(Rive_File *file) {
  if (!file)
    return nullptr;

  rive::File *cpp_file = reinterpret_cast<rive::File *>(file);
  return reinterpret_cast<Rive_ArtboardInstance *>(
      cpp_file->artboardDefault().release());
};

Rive_ViewModelRuntime *
rive_defaultArtboardViewModel(Rive_File *file,
                              Rive_ArtboardInstance *artboard) {
  auto *cpp_artboard = reinterpret_cast<rive::ArtboardInstance *>(artboard);
  auto *cpp_file = reinterpret_cast<rive::File *>(file);
  return reinterpret_cast<Rive_ViewModelRuntime *>(
      cpp_file->defaultArtboardViewModel(cpp_artboard));
}

// headless factory for testing
Rive_Factory *rive_factory_createHeadless() {
  return reinterpret_cast<Rive_Factory *>(new rive::NoOpFactory());
}

Rive_ViewModelInstance *rive_createDefaultViewModelInstanceFromArtboard(
    Rive_File *self, Rive_ArtboardInstance *artboard) {
  auto *cpp_artboard = reinterpret_cast<rive::ArtboardInstance *>(artboard);
  auto *cpp_file = reinterpret_cast<rive::File *>(self);
  return reinterpret_cast<Rive_ViewModelInstance *>(
      cpp_file->createDefaultViewModelInstance(cpp_artboard).release());
}

// rive::ArtboardInstance
size_t rive_artboard_stateMachineCount(Rive_ArtboardInstance *artboard) {
  if (!artboard)
    return 0;

  rive::ArtboardInstance *cpp_artboard =
      reinterpret_cast<rive::ArtboardInstance *>(artboard);
  return cpp_artboard->stateMachineCount();
}

Rive_StateMachineInstance *
rive_artboard_defaultStateMachine(Rive_ArtboardInstance *artboard) {
  if (!artboard)
    return nullptr;

  rive::ArtboardInstance *cpp_artboard =
      reinterpret_cast<rive::ArtboardInstance *>(artboard);
  return reinterpret_cast<Rive_StateMachineInstance *>(
      cpp_artboard->defaultStateMachine().release());
}

Rive_StateMachineInstance *
rive_artboard_stateMachineAt(Rive_ArtboardInstance *artboard, size_t index) {
  if (!artboard)
    return nullptr;

  rive::ArtboardInstance *cpp_artboard =
      reinterpret_cast<rive::ArtboardInstance *>(artboard);
  return reinterpret_cast<Rive_StateMachineInstance *>(
      cpp_artboard->stateMachineAt(index).release());
}

void Rive_ArtboardReset(Rive_ArtboardInstance *artboard) {

  rive::ArtboardInstance *cpp_artboard =
      reinterpret_cast<rive::ArtboardInstance *>(artboard);

  cpp_artboard->reset();
}

void rive_artboardSetWidth(Rive_ArtboardInstance *artboard, float width) {
  reinterpret_cast<rive::ArtboardInstance *>(artboard)->width(width);
}
void rive_artboardSetHeight(Rive_ArtboardInstance *artboard, float height) {
  reinterpret_cast<rive::ArtboardInstance *>(artboard)->height(height);
}

void rive_artboardBindViewModelInstance(Rive_ArtboardInstance *artboard,
                                        Rive_ViewModelInstance *vmi) {
  auto *cpp_artboard = reinterpret_cast<rive::ArtboardInstance *>(artboard);
  auto *cpp_vmi = reinterpret_cast<rive::ViewModelInstance *>(vmi);
  rive::rcp<rive::ViewModelInstance> cpp_vmi_rcp(cpp_vmi);
  cpp_artboard->bindViewModelInstance(cpp_vmi_rcp);
}

// rive::stateMachineInstance
void rive_SMIadvanceAndApply(Rive_StateMachineInstance *sm, float secs) {
  if (sm) {
    rive::StateMachineInstance *cpp_smi =
        reinterpret_cast<rive::StateMachineInstance *>(sm);
    cpp_smi->advanceAndApply(secs);
  }
}

void rive_SMIdraw(Rive_StateMachineInstance *sm, Rive_RiveRenderer *renderer) {
  if (sm) {
    rive::StateMachineInstance *cpp_smi =
        reinterpret_cast<rive::StateMachineInstance *>(sm);
    rive::Renderer *cpp_renderer = reinterpret_cast<rive::Renderer *>(renderer);
    cpp_smi->draw(cpp_renderer);
  }
}
void rive_stateMachineBindViewModelInstance(Rive_StateMachineInstance *smi,
                                            Rive_ViewModelInstance *vmi) {
  auto *cpp_smi = reinterpret_cast<rive::StateMachineInstance *>(smi);
  auto *cpp_vmi = reinterpret_cast<rive::ViewModelInstance *>(vmi);
  rive::rcp<rive::ViewModelInstance> cpp_vmi_rcp(cpp_vmi);
  cpp_smi->bindViewModelInstance(cpp_vmi_rcp);
}

void rive_pointerDown(Rive_StateMachineInstance *self, float x, float y) {
  auto *cpp_smi = reinterpret_cast<rive::StateMachineInstance *>(self);
  cpp_smi->pointerDown({x, y});
}

void rive_pointerUp(Rive_StateMachineInstance *self, float x, float y) {
  auto *cpp_smi = reinterpret_cast<rive::StateMachineInstance *>(self);
  cpp_smi->pointerUp({x, y});
}

// TODO: Maybe use Vec2D instaed of float x and y?
void rive_pointerMove(Rive_StateMachineInstance *self, float x, float y) {
  auto *cpp_smi = reinterpret_cast<rive::StateMachineInstance *>(self);
  cpp_smi->pointerMove({x, y});
}

// rive::renderContext
void rive_contextBeginFrame(Rive_RenderContext *context,
                            Rive_FrameDescriptor fd) {
  if (context) {
    auto *cpp_context = reinterpret_cast<rive::gpu::RenderContext *>(context);

    cpp_context->beginFrame({
        .renderTargetWidth = fd.render_target_width,
        .renderTargetHeight = fd.render_target_height,
        .clearColor = fd.clear_color,
    });
  }
}

void rive_contextFlush(Rive_RenderContext *context,
                       Rive_FlushResources *flush) {
  if (context) {
    rive::gpu::RenderContext *cpp_context =
        reinterpret_cast<rive::gpu::RenderContext *>(context);

    cpp_context->flush(
        {.renderTarget =
             reinterpret_cast<rive::gpu::RenderTarget *>(flush->renderTarget),
         .externalCommandBuffer = flush->externalCommandBuffer});
  }
}

Rive_RiveRenderer *rive_getRendererFromContext(Rive_RenderContext *context) {
  rive::gpu::RenderContext *cpp_context =
      reinterpret_cast<rive::gpu::RenderContext *>(context);
  rive::RiveRenderer *renderer = new rive::RiveRenderer(cpp_context);
  return reinterpret_cast<Rive_RiveRenderer *>(renderer);
}

Rive_Factory *rive_contextToFactory(Rive_RenderContext *context) {
  return reinterpret_cast<Rive_Factory *>(context);
}

// rive::riveRenderer

void rive_rendererSave(Rive_RiveRenderer *renderer) {

  rive::RiveRenderer *cpp_renderer =
      reinterpret_cast<rive::RiveRenderer *>(renderer);
  cpp_renderer->save();
}

void rive_rendererRestore(Rive_RiveRenderer *renderer) {

  rive::RiveRenderer *cpp_renderer =
      reinterpret_cast<rive::RiveRenderer *>(renderer);
  cpp_renderer->restore();
}

// TODO: temporary: this is too high level for this api. need to implement
// transform function

void rive_rendererDPIScale(Rive_RiveRenderer *renderer, float dpiScale) {
  auto *cpp_renderer = reinterpret_cast<rive::RiveRenderer *>(renderer);
  cpp_renderer->transform(rive::Mat2D::fromScale(dpiScale, dpiScale));
}

// stub
void rive_rendererAlign(Rive_RiveRenderer *renderer, Rive_Fit *fit,
                        Rive_Alignment *alignment, float scaleFactor) {

  // rive::Alignment cpp_alignment = static_cast<rive::Alignment>(alignment);
  rive::RiveRenderer *cpp_renderer =
      reinterpret_cast<rive::RiveRenderer *>(renderer);
  // cpp_renderer->align();
  cpp_renderer->save();
}
void rive_freeRenderer(Rive_RiveRenderer *renderer) {
  delete reinterpret_cast<rive::RiveRenderer *>(renderer);
}

// rive::gpu::RenderTarget
int rive_renderTargetGetWidth(void *target) {
  auto *cpp_target = static_cast<rive::gpu::RenderTarget *>(target);
  return cpp_target->width();
}

int rive_renderTargetGetHeight(void *target) {
  auto *cpp_target = static_cast<rive::gpu::RenderTarget *>(target);
  return cpp_target->height();
}

// rive::ViewModelRuntime

Rive_ViewModelInstanceRuntime *
rive_createDefaultVMInstance(Rive_ViewModelRuntime *vm) {
  auto *cpp_vm = reinterpret_cast<rive::ViewModelRuntime *>(vm);
  auto rcp = cpp_vm->createDefaultInstance();
  return reinterpret_cast<Rive_ViewModelInstanceRuntime *>(
      cpp_vm->createDefaultInstance().release());
}

// rive::ViewModelInstanceRuntime

Rive_ViewModelInstance *
rive_getViewModelInstance(Rive_ViewModelInstanceRuntime *vmi) {
  auto *cpp_vmi = reinterpret_cast<rive::ViewModelInstanceRuntime *>(vmi);
  rive::rcp<rive::ViewModelInstanceRuntime> cpp_vmi_rcp(cpp_vmi);
  return reinterpret_cast<Rive_ViewModelInstance *>(
      cpp_vmi_rcp->instance().release());
}

// rive::viewModelInstance
Rive_VMI_Number *rive_getVMINumber(Rive_ViewModelInstance *self,
                                   const char *name) {
  auto *cpp_vmi = reinterpret_cast<rive::ViewModelInstance *>(self);
  auto propValue = cpp_vmi->propertyValue(name);
  if (propValue) {
    auto vmiNumber = propValue->as<rive::ViewModelInstanceNumber>();
    return reinterpret_cast<Rive_VMI_Number *>(vmiNumber);

  } else {
    return nullptr;
  }
}

Rive_VMI_Boolean *rive_getVMIBoolean(Rive_ViewModelInstance *self,
                                     const char *name) {
  auto *cpp_vmi = reinterpret_cast<rive::ViewModelInstance *>(self);
  auto ret = cpp_vmi->propertyValue(name)->as<rive::ViewModelInstanceBoolean>();

  return reinterpret_cast<Rive_VMI_Boolean *>(ret);
}

Rive_VMI_Trigger *rive_getVMITrigger(Rive_ViewModelInstance *self,
                                     const char *name) {
  auto *cpp_vmi = reinterpret_cast<rive::ViewModelInstance *>(self);
  auto propValue = cpp_vmi->propertyValue(name);
  if (propValue) {

    auto ret = propValue->as<rive::ViewModelInstanceTrigger>();
    return reinterpret_cast<Rive_VMI_Trigger *>(ret);
  } else {
    return nullptr;
  }

}

Rive_VMI_Color *rive_getVMIColor(Rive_ViewModelInstance *self,
                                 const char *name) {
  auto *cpp_vmi = reinterpret_cast<rive::ViewModelInstance *>(self);
  auto propValue = cpp_vmi->propertyValue(name);
  if (propValue) {
    auto vmiColor = propValue->as<rive::ViewModelInstanceColor>();
    return reinterpret_cast<Rive_VMI_Color *>(vmiColor);

  } else {
    return nullptr;
  }
}

Rive_VMI_Enum *rive_getVMIEnum(Rive_ViewModelInstance *self,
                               const char *name) {
  auto *cpp_vmi = reinterpret_cast<rive::ViewModelInstance *>(self);
  auto propValue = cpp_vmi->propertyValue(name);
  if (propValue) {
    auto vmiEnum = propValue->as<rive::ViewModelInstanceEnum>();
    return reinterpret_cast<Rive_VMI_Enum *>(vmiEnum);

  } else {
    return nullptr;
  }
}

// View Model Property setters and getters

float rive_getVMINumberValue(Rive_VMI_Number *self) {
  auto *cpp_num = reinterpret_cast<rive::ViewModelInstanceNumber *>(self);
  return cpp_num->propertyValue();
}

void rive_setVMINumberValue(Rive_VMI_Number *self, float value) {
  auto *cpp_num = reinterpret_cast<rive::ViewModelInstanceNumber *>(self);
  cpp_num->propertyValue(value);
}

uint32_t rive_getVMIColorValue(Rive_VMI_Color *self) {
  auto *cpp_color = reinterpret_cast<rive::ViewModelInstanceColor *>(self);
  return cpp_color->propertyValue();
}

void rive_setVMIColorValue(Rive_VMI_Color *self, uint32_t value) {
  auto *cpp_color = reinterpret_cast<rive::ViewModelInstanceColor *>(self);
  cpp_color->propertyValue(value);
}

uint32_t rive_getVMIEnumValue(Rive_VMI_Enum *self) {
  auto *cpp_enum = reinterpret_cast<rive::ViewModelInstanceEnum *>(self);
  return cpp_enum->propertyValue();
}

void rive_setVMIEnumValue(Rive_VMI_Enum *self, uint32_t value) {
  auto *cpp_enum = reinterpret_cast<rive::ViewModelInstanceEnum *>(self);
  cpp_enum->propertyValue(value);
}

bool rive_getVMIBooleanValue(Rive_VMI_Boolean *self) {
  auto *cpp_bool = reinterpret_cast<rive::ViewModelInstanceBoolean *>(self);
  return cpp_bool->propertyValue();
}

void rive_setVMIBooleanValue(Rive_VMI_Boolean *self, bool value) {
  auto *cpp_bool = reinterpret_cast<rive::ViewModelInstanceBoolean *>(self);
  cpp_bool->propertyValue(value);
}

uint32_t rive_getVMITriggerValue(Rive_VMI_Trigger *self) {
  auto *cpp_trig = reinterpret_cast<rive::ViewModelInstanceTrigger *>(self);
  return cpp_trig->propertyValue();
}
void rive_fireVMITrigger(Rive_VMI_Trigger *self) {
  auto *cpp_trig = reinterpret_cast<rive::ViewModelInstanceTrigger *>(self);
  cpp_trig->trigger();
}


void rive_VMITriggerSetCallback(Rive_VMI_Trigger *self, void (*callback)()) {
  auto *cpp_trig = reinterpret_cast<rive::ViewModelInstanceTrigger *>(self);
  auto *cpp_callback = reinterpret_cast<rive::ViewModelTriggerChanged>(callback);

  cpp_trig->onChanged(cpp_callback);

}


// TODO: figure out how to release

// void rive_VMRuntimeRelease(Rive_ViewModelInstanceRuntime* instance) {
//   auto* cpp_instance = reinterpret_cast<rive::ViewModelInstanceRuntime*>()
//   rive::rcp<rive::ViewModelInstanceRuntime >
//   instance_to_release(reinterpret_cast<rive::File*>(file));
//
// }

} // end extern "C"
