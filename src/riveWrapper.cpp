
#include "rive/animation/state_machine_instance.hpp"
#include "rive/artboard.hpp"
#include "rive/factory.hpp"
#include "rive/file.hpp"
#include "rive/span.hpp"
#include "rive/renderer/rive_renderer.hpp"
#include "rive/renderer/render_context.hpp"
#include "utils/no_op_factory.hpp"
#include <cstddef>
#include <cstdint>
#include <memory>

#include "riveWrapper.h"


struct Rive_File : public rive::File {

  using rive::File::import;
};

extern "C" {

//
Rive_File *rive_file_import(const uint8_t* data, size_t size,
                           Rive_Factory* factory, Rive_ImportResult* out_result) {

  rive::Span<const uint8_t> data_span(data, size);
  rive::Factory* cpp_factory = reinterpret_cast<rive::Factory *>(factory);
  rive::ImportResult cpp_result;

  //rive::file

  rive::rcp<rive::File> file = rive::File::import(data_span, cpp_factory, &cpp_result);

  if (out_result) {
    *out_result = static_cast<Rive_ImportResult>(cpp_result);
  }
  if (!file || cpp_result != rive::ImportResult::success) {
    return nullptr;
  }

  //unwrap from rcp
  return reinterpret_cast<Rive_File *>(file.release());
}

void rive_file_release(Rive_File *file) {
  if (file) {

    // rewrap into rcp
    rive::rcp<rive::File> file_to_clean(reinterpret_cast<rive::File*>(file));
  }
}

Rive_ArtboardInstance* rive_file_artboardDefault(Rive_File* file) {
  if (!file) return nullptr;

  rive::File* cpp_file = reinterpret_cast<rive::File*>(file);
  return reinterpret_cast<Rive_ArtboardInstance*>(cpp_file->artboardDefault().release());

};


//headless factory for testing
Rive_Factory* rive_factory_createHeadless(){
  return reinterpret_cast<Rive_Factory*>(new rive::NoOpFactory());
}

//rive::Artboard
size_t rive_artboard_stateMachineCount(Rive_ArtboardInstance* artboard) {
  if (!artboard) return 0;

  rive::ArtboardInstance* cpp_artboard = reinterpret_cast<rive::ArtboardInstance*>(artboard);
  return cpp_artboard->stateMachineCount();
}

Rive_StateMachineInstance* rive_artboard_defaultStateMachine(Rive_ArtboardInstance* artboard) {
  if (!artboard) return nullptr;

  rive::ArtboardInstance* cpp_artboard = reinterpret_cast<rive::ArtboardInstance*>(artboard);
  return reinterpret_cast<Rive_StateMachineInstance*>(cpp_artboard->defaultStateMachine().release());
}

Rive_StateMachineInstance* rive_artboard_stateMachineAt(Rive_ArtboardInstance* artboard, size_t index) {
  if (!artboard) return nullptr;

  rive::ArtboardInstance* cpp_artboard = reinterpret_cast<rive::ArtboardInstance*>(artboard);
  return reinterpret_cast<Rive_StateMachineInstance*>(cpp_artboard->stateMachineAt(index).release());

}

void Rive_ArtboardReset(Rive_ArtboardInstance* artboard) {

  rive::ArtboardInstance* cpp_artboard = reinterpret_cast<rive::ArtboardInstance*>(artboard);

  cpp_artboard->reset();

}

//rive::stateMachineInstance
void rive_SMIadvanceAndApply(Rive_StateMachineInstance* sm, float secs) {
  if (sm) {
    rive::StateMachineInstance* cpp_smi = reinterpret_cast<rive::StateMachineInstance*>(sm);
    cpp_smi->advanceAndApply(secs);
  }
}

void rive_SMIdraw(Rive_StateMachineInstance* sm, Rive_RiveRenderer* renderer) {
  if (sm) {
    rive::StateMachineInstance* cpp_smi = reinterpret_cast<rive::StateMachineInstance*>(sm);
    rive::RiveRenderer* cpp_renderer = reinterpret_cast<rive::RiveRenderer*>(renderer);
    cpp_smi->draw(cpp_renderer);

  }
}

//rive::renderContext
void rive_contextBeginFrame(Rive_RenderContext* context, Rive_FrameDescriptor* fd) {
  if (context) {
    rive::gpu::RenderContext* cpp_context = reinterpret_cast<rive::gpu::RenderContext*>(context);
    rive::gpu::RenderContext::FrameDescriptor* cpp_descriptor = reinterpret_cast<rive::gpu::RenderContext::FrameDescriptor*>(fd);

    cpp_context->beginFrame(*cpp_descriptor);
  }

}
void rive_contextFlush(Rive_RenderContext* context, Rive_FlushResources* flush) {
  if (context) {
    rive::gpu::RenderContext* cpp_context = reinterpret_cast<rive::gpu::RenderContext*>(context);
    rive::gpu::RenderContext::FlushResources* cpp_flush = reinterpret_cast<rive::gpu::RenderContext::FlushResources*>(flush);

    cpp_context->flush(*cpp_flush);
  }

}

//rive::riveRenderer

void rive_rendererSave(Rive_RiveRenderer* renderer) {

    rive::RiveRenderer* cpp_renderer = reinterpret_cast<rive::RiveRenderer*>(renderer);
    cpp_renderer->save();

}

void rive_rendererRestore(Rive_RiveRenderer* renderer) {

    rive::RiveRenderer* cpp_renderer = reinterpret_cast<rive::RiveRenderer*>(renderer);
    cpp_renderer->restore();

}

//stub
void rive_rendererAlign(Rive_RiveRenderer* renderer, Rive_Fit* fit, Rive_Alignment* alignment, float scaleFactor) {

    // rive::Alignment cpp_alignment = static_cast<rive::Alignment>(alignment);
    rive::RiveRenderer* cpp_renderer = reinterpret_cast<rive::RiveRenderer*>(renderer);
    // cpp_renderer->align();
    cpp_renderer->save();

}












}//end extern "C"

