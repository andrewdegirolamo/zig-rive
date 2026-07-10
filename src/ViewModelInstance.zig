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
pub fn getBoolean(self: @This(), name: [:0]const u8) !Boolean {
    const ret = c.rive_getVMIBoolean(self.value, name);

    if (ret) |num| {
        return .{ .ref = num };
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

pub fn getColor(self: @This(), name: [:0]const u8) !Color {
    const ret = c.rive_getVMIColor(self.value, name);

    if (ret) |col| {
        return .{ .ref = col };
    } else {
        return error.PropertyNotFound;
    }
}

pub fn getEnum(self: @This(), name: [:0]const u8) !Enum {
    const ret = c.rive_getVMIEnum(self.value, name);

    if (ret) |enm| {
        return .{ .ref = enm };
    } else {
        return error.PropertyNotFound;
    }
}
pub fn getList(self: @This(), name: [:0]const u8) !List {
    const ret = c.rive_getVMIList(self.value, name);

    if (ret) |enm| {
        return .{ .ref = enm };
    } else {
        return error.PropertyNotFound;
    }
}
pub fn createListItem(self: @This()) List.ListItem {
    return .{ .ref = c.rive_VMIlistItemInit(self.value) };
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

pub const Enum = struct {
    ref: *c.Rive_VMI_Enum,
    pub inline fn getValue(self: Enum) u32 {
        return c.rive_getVMIEnumValue(self.ref);
    }
    pub inline fn setValue(self: Enum, value: u32) void {
        return c.rive_setVMIEnumValue(self.ref, value);
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
pub const List = struct {
    ref: *c.Rive_VMI_List,
    pub const ListItem = struct {
        ref: *c.Rive_VMI_ListItem,
        pub inline fn addVMI(self: ListItem, vmi: @This()) void {
            c.rive_VMIlistItemAddVMI(self.ref, vmi.ref);
        }
    };

    //Todo: error handling

    pub inline fn getListItemAt(self: List, index: u32) ListItem {
        return .{ .ref = c.rive_getVMIListItem(self.ref, index) };
    }
    pub inline fn addItem(self: List, item: ListItem) void {
        c.rive_VMIListAddItem(self.ref, item.ref);
    }
    pub inline fn addItemAt(self: List, item: ListItem, index: u32) void {
        c.rive_VMIListAddItemAt(self.ref, item.ref, index);
    }
    pub inline fn removeAll(self: List) void {
        c.rive_VMIListRemoveAll(self.ref);
    }
    pub inline fn removeItemAt(self: List, index: u32) void {
        c.rive_VMIListRemoveItemAt(self.ref, index);
    }
    pub inline fn pop(self: List) ListItem {
        return .{ .ref = c.rive_VMIListPop(self.ref) };
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
