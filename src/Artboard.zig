const std = @import("std");
const c = @import("c");
const errors = @import("errrors.zig");
const smi = @import("StateMachineInstance.zig");

///TODO: Write documentation
pub const ArtboardInstance = struct {
    value: *c.Rive_ArtboardInstance,
    pub inline fn stateMachineCount(self: @This()) usize {
        return c.rive_artboard_stateMachineCount(self.value);
    }
    pub inline fn defaultStateMachine(self: @This()) !smi {
        return .{ .value = try errors.wrapNull(*c.Rive_StateMachineInstance, c.rive_artboard_defaultStateMachine(self.value)) };
    }
    pub inline fn stateMachineAt(self: @This(), index: usize) !smi {
        return .{ .value = try errors.wrapNull(*c.Rive_StateMachineInstance, c.rive_artboard_stateMachineAt(self.value, index)) };
    }
    pub inline fn setWidth(self: @This(), width: f32) void {
        c.rive_artboardSetWidth(self.value, width);
    }

    pub inline fn setHeight(self: @This(), height: f32) void {
        c.rive_artboardSetHeight(self.value, height);
    }
};
