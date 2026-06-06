#pragma once

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

// These are opaque type handles
typedef struct Rive_File Rive_File;
typedef struct Rive_Factory Rive_Factory;
typedef struct Rive_Artboard_Instance Rive_ArtboardInstance;
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
typedef struct Rive_FlushResources {
  Rive_RenderTarget *renderTarget;
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

// rive::stateMachineInstance
void rive_SMIadvanceAndApply(Rive_StateMachineInstance *sm, float secs);

// rive::RenderContext
void rive_contextBeginFrame(Rive_RenderContext *context,
                            Rive_FrameDescriptor *fd);
void rive_contextFlush(Rive_RenderContext *context, Rive_FlushResources *flush);

// rive::RiveRenderer
void rive_rendererSave(Rive_RiveRenderer *renderer);

// BindeableArtboard

#ifdef __cplusplus
}
#endif // __cplusplus
