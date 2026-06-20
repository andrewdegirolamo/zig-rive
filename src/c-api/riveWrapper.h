#pragma once

#include <stdbool.h>
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
typedef struct Rive_ViewModelRuntime Rive_ViewModelRuntime;
typedef struct Rive_ViewModelInstanceRuntime Rive_ViewModelInstanceRuntime;
typedef struct Rive_ViewModelInstance Rive_ViewModelInstance;
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
  void *externalCommandBuffer;
} Rive_FlushResources;

typedef struct Rive_rcpRenderTarget Rive_rcpRenderTarget;

typedef struct Rive_Alignment {
  float m_x, m_y;
} Rive_Alignment;

// Data binding types

typedef struct Rive_VMI_Number Rive_VMI_Number;
typedef struct Rive_VMI_String Rive_VMI_String;
typedef struct Rive_VMI_Color Rive_VMI_Color;
typedef struct Rive_VMI_Boolean Rive_VMI_Boolean;
typedef struct Rive_VMI_Trigger Rive_VMI_Trigger;
typedef struct Rive_VMI_Enum Rive_VMI_Enum;
typedef struct Rive_VMI_Property Rive_VMI_Property;

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

// for testing
Rive_Factory *rive_factory_createHeadless();
// rive::File
Rive_File *rive_file_import(const uint8_t *data, size_t size,
                            Rive_Factory *factory,
                            Rive_ImportResult *out_result);
void rive_file_release(Rive_File *file);
Rive_ArtboardInstance *rive_file_artboardDefault(Rive_File *file);
Rive_ViewModelRuntime *
rive_defaultArtboardViewModel(Rive_File *file, Rive_ArtboardInstance *artboard);
Rive_ViewModelInstance *rive_createDefaultViewModelInstanceFromArtboard(
    Rive_File *self, Rive_ArtboardInstance *artboard);

// rive::Artboard
size_t rive_artboard_stateMachineCount(Rive_ArtboardInstance *artboard);
Rive_StateMachineInstance *
rive_artboard_defaultStateMachine(Rive_ArtboardInstance *artboard);
Rive_StateMachineInstance *
rive_artboard_stateMachineAt(Rive_ArtboardInstance *artboard, size_t index);
void rive_artboardSetWidth(Rive_ArtboardInstance *artboard, float width);
void rive_artboardSetHeight(Rive_ArtboardInstance *artboard, float height);
void rive_artboardBindViewModelInstance(Rive_ArtboardInstance *artboard,
                                        Rive_ViewModelInstance *vmi);

// rive::stateMachineInstance
void rive_SMIadvanceAndApply(Rive_StateMachineInstance *sm, float secs);
void rive_SMIdraw(Rive_StateMachineInstance *sm,
                  Rive_RiveRenderer *renderer); // this should be scene not smi
void rive_stateMachineBindViewModelInstance(Rive_StateMachineInstance *smi,
                                            Rive_ViewModelInstance *vmi);
void rive_pointerMove(Rive_StateMachineInstance *self, float x, float y);
void rive_pointerDown(Rive_StateMachineInstance *self, float x, float y);
void rive_pointerUp(Rive_StateMachineInstance *self, float x, float y);

// rive::RenderContext
void rive_contextBeginFrame(Rive_RenderContext *context,
                            Rive_FrameDescriptor fd);

void rive_contextFlush(Rive_RenderContext *context, Rive_FlushResources *flush);
void rive_setMetalCommandQueue(Rive_RenderContext *context, void *queue);

Rive_Factory *rive_contextToFactory(Rive_RenderContext *context);

Rive_RenderContext *rive_MakeContextMetal(void *mtl_device);
Rive_RiveRenderer *rive_getRendererFromContext(Rive_RenderContext *context);
Rive_RenderTargetMetal *rive_getMetalRenderTarget(Rive_RenderContext *context,
                                                  uint32_t width,
                                                  uint32_t height);

void rive_setMetalTargetTexture(Rive_RenderTargetMetal *target,
                                void *frame_surface);

// rive::gpu::renderTargetMetal

int rive_metalRenderTargetRelease(Rive_RenderTargetMetal *self);

// rive::RiveRenderer
void rive_rendererSave(Rive_RiveRenderer *renderer);
void rive_rendererRestore(Rive_RiveRenderer *renderer);
void rive_freeRenderer(Rive_RiveRenderer *renderer);
void rive_rendererDPIScale(Rive_RiveRenderer *renderer, float dpiScale);

// rive::renderTarget
int rive_renderTargetGetWidth(void *target);
int rive_renderTargetGetHeight(void *target);

// rive::ViewModelRuntime

Rive_ViewModelInstanceRuntime *
rive_createDefaultVMInstance(Rive_ViewModelRuntime *vm);

// rive::ViewModelInstanceRuntime

Rive_ViewModelInstance *
rive_getViewModelInstance(Rive_ViewModelInstanceRuntime *vmi);

// view model instance properties

Rive_VMI_Number *rive_getVMINumber(Rive_ViewModelInstance *self,
                                   const char *name);

Rive_VMI_Boolean *rive_getVMIBoolean(Rive_ViewModelInstance *self,
                                     const char *name);
Rive_VMI_Trigger *rive_getVMITrigger(Rive_ViewModelInstance *self,
                                     const char *name);
Rive_VMI_Color *rive_getVMIColor(Rive_ViewModelInstance *self,
                                 const char *name);
float rive_getVMINumberValue(Rive_VMI_Number *self);
void rive_setVMINumberValue(Rive_VMI_Number *self, float value);
bool rive_getVMIBooleanValue(Rive_VMI_Boolean *self);
void rive_setVMIBooleanValue(Rive_VMI_Boolean *self, bool value);
uint32_t rive_getVMIColorValue(Rive_VMI_Color *self);
void rive_setVMIColorValue(Rive_VMI_Color *self, uint32_t value);
uint32_t rive_getVMITriggerValue(Rive_VMI_Trigger *self);
void rive_fireVMITrigger(Rive_VMI_Trigger *self);
void rive_VMITriggerSetCallback(Rive_VMI_Trigger *self, void (*callback)());

#ifdef __cplusplus
}
#endif // __cplusplus
