pub const File = @import("File.zig");
pub const Factory = @import("Factory.zig");
pub const gpu = @import("gpu.zig");
pub const artboard = @import("Artboard.zig");
pub const StateMachineInstance = @import("StateMachineInstance.zig");
const c = @import("c");
const errors = @import("errrors.zig");

pub const RiveRenderer = @import("RiveRenderer.zig");
//TODO:: Categorize this better?

pub const RenderTargetMetal = struct {
    value: *c.Rive_RenderTargetMetal,
    pub inline fn setTargetTexture(self: *@This(), texture: ?*anyopaque) void {
        c.rive_setMetalTargetTexture(self.value, texture);
    }
};
