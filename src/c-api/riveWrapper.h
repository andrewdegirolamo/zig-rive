#pragma once

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

// These are opaque type handles
typedef struct Rive_File Rive_File;
typedef struct Rive_Factory Rive_Factory;
typedef struct Rive_ArtboardInstance Rive_ArtboardInstance;
typedef struct Rive_StateMachineInstance Rive_StateMachineInstance;
typedef struct Rive_RenderContext Rive_RenderContext;
typedef struct Rive_FrameDescriptor {
  uint32_t render_target_width;
  uint32_t render_target_height;
  uint32_t clear_color;
} Rive_FrameDescriptor;

typedef struct Rive_RiveRenderer {
  Rive_RenderContext *render_Context;
} Rive_RiveRenderer;

typedef struct Rive_RenderTarget Rive_RenderTarget;
typedef struct Rive_RenderTargetMetal Rive_RenderTargetMetal;
typedef struct Rive_FlushResources {
  Rive_RenderTarget *renderTarget;
  void* externalCommandBuffer;
} Rive_FlushResources;

typedef struct Rive_Alignment {
  float m_x, m_y;
} Rive_Alignment;

typedef enum {
  RIVE_IMPORT_SUCCESS = 0,
  RIVE_IMPORT_UNSUPPORTED_VERSION = 1,
  RIVE_IMPORT_MALFORMED = 2,
} Rive_ImportResult;

typedef enum {
  FILL = 0,
  CONTAIN = 1,
  COVER = 2,
  FITWIDTH = 3,
  FITHEIGHT = 4,
  NONE = 5,
  SCALEDOWN = 6,
  LAYOUT = 7,
} Rive_Fit;


//for testing
Rive_Factory* rive_factory_createHeadless();
// rive::File
Rive_File *rive_file_import(const uint8_t *data, size_t size,
                            Rive_Factory *factory,
                            Rive_ImportResult *out_result);
void rive_file_release(Rive_File *file);
Rive_ArtboardInstance *rive_file_artboardDefault(Rive_File *file);

// rive::Artboard
size_t rive_artboard_stateMachineCount(Rive_ArtboardInstance *artboard);
Rive_StateMachineInstance *
rive_artboard_defaultStateMachine(Rive_ArtboardInstance *artboard);
Rive_StateMachineInstance *
rive_artboard_stateMachineAt(Rive_ArtboardInstance *artboard, size_t index);
void rive_artboardSetWidth(Rive_ArtboardInstance* artboard, float width);
void rive_artboardSetHeight(Rive_ArtboardInstance* artboard, float height);

// rive::stateMachineInstance
void rive_SMIadvanceAndApply(Rive_StateMachineInstance *sm, float secs);
void rive_SMIdraw(Rive_StateMachineInstance* sm, Rive_RiveRenderer* renderer); //this should be scene not smi

// rive::RenderContext
void rive_contextBeginFrame(Rive_RenderContext *context,
                            Rive_FrameDescriptor fd);

void rive_contextFlush(Rive_RenderContext *context, Rive_FlushResources *flush);
void rive_setMetalCommandQueue(Rive_RenderContext *context, void *queue);

Rive_Factory* rive_contextToFactory(Rive_RenderContext *context);

Rive_RenderContext *rive_MakeContextMetal(void *mtl_device);
Rive_RiveRenderer* rive_getRendererFromContext(Rive_RenderContext* context);
Rive_RenderTargetMetal* rive_getMetalRenderTarget(Rive_RenderContext *context, uint32_t width, uint32_t height);

void rive_setMetalTargetTexture(Rive_RenderTargetMetal *target, void *frame_surface);


// rive::RiveRenderer
void rive_rendererSave(Rive_RiveRenderer *renderer);
void rive_rendererRestore(Rive_RiveRenderer* renderer);
void rive_freeRenderer(Rive_RiveRenderer* renderer);
void rive_rendererDPIScale(Rive_RiveRenderer* renderer, float dpiScale);

//rive::renderTarget
int rive_renderTargetGetWidth(void* target);
int rive_renderTargetGetHeight(void* target);

// BindeableArtboard

#ifdef __cplusplus
}
#endif // __cplusplus
