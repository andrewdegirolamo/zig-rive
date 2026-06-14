const c = @import("c");
const errors = @import("errrors.zig");
const RiveRenderer = @import("RiveRenderer.zig");

value: *c.Rive_StateMachineInstance,

pub inline fn advanceAndApply(self: @This(), secs: f32) void {
    c.rive_SMIadvanceAndApply(self.value, secs);
}

pub inline fn draw(self: @This(), renderer: RiveRenderer) void {
    c.rive_SMIdraw(self.value, renderer.value);
}
