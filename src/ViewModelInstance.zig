const rive = @import("rive.zig");
const c = @import("c");
const errors = @import("errors.zig");
const std = @import("std");

value: *c.Rive_ViewModelInstance,

pub fn getNumber(self: @This(), name: [:0]const u8) !Number {
    const ret = c.rive_getVMINumber(self.value, name);

    if (ret) |num| {
        return .{ .ref = num };
    } else {
        return error.PropertyNotFound;
    }
}

pub fn getColor(self: @This(), name: [:0]const u8) !Color {
    const ret = c.rive_getVMIColor(self.value, name);

    if (ret) |col| {
        return .{ .ref = col };
    } else {
        return error.PropertyNotFound;
    }
}

pub fn getTrigger(self: @This(), name: [:0]const u8) !Trigger {
    const ret = c.rive_getVMITrigger(self.value, name);

    if (ret) |trig| {
        return .{ .ref = trig };
    } else {
        return error.PropertyNotFound;
    }
}

//using ref instead of value so as not to conflate with view model property values

pub const Number = struct {
    ref: *c.Rive_VMI_Number,
    pub inline fn getValue(self: Number) f32 {
        return c.rive_getVMINumberValue(self.ref);
    }
    pub inline fn setValue(self: Number, value: f32) void {
        return c.rive_setVMINumberValue(self.ref, value);
    }
};

pub const Color = struct {
    ref: *c.Rive_VMI_Color,
    pub inline fn getValue(self: Color) u32 {
        return c.rive_getVMIColorValue(self.ref);
    }
    pub inline fn setValue(self: Color, value: u32) void {
        return c.rive_setVMIColorValue(self.ref, value);
    }
};

pub const Boolean = struct {
    ref: *c.Rive_VMI_Boolean,
    pub inline fn getValue(self: Boolean) bool {
        return c.rive_getVMIBooleanValue(self.ref);
    }
    pub inline fn setValue(self: Boolean, value: bool) void {
        return c.rive_setVMIBoolValue(self.ref, value);
    }
};

pub const Trigger = struct {
    ref: *c.Rive_VMI_Trigger,
    callback: ?*const fn () void = null,
    var registry: ?Registry = null;

    const Registry = std.AutoHashMap(*c.Rive_VMI_Trigger, *const Trigger);

    pub inline fn getValue(self: Trigger) u32 {
        return c.rive_getVMITriggerValue(self.ref);
    }
    pub inline fn trigger(self: Trigger) void {
        return c.rive_fireVMITrigger(self.ref);
    }
    pub inline fn setCallback(self: *Trigger, allocator: std.mem.Allocator, new_callback: *const fn () void) !void {
        self.callback = new_callback;
        if (registry == null) {
            registry = Registry.init(allocator);
        }
        try registry.?.put(self.ref, self);

        c.rive_VMITriggerSetCallback(self.ref, @ptrCast(&onTrigger));
    }

    pub fn deinit(self: Trigger) void {
        if (registry) |*reg| {
            _ = reg.remove(self.ref);
            reg.deinit();
        }
    }

    fn onTrigger(ref_ptr: *anyopaque, value: u32) callconv(.c) void {
        if (value == 1) {
            const c_ref: *c.Rive_VMI_Trigger = @ptrCast(ref_ptr);
            if (registry.?.get(c_ref)) |self| {
                (self.callback.?)();
            }
        }
    }
};
