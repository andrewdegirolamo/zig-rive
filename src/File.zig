//! File rive!
const c = @import("c");
const Factory = @import("Factory.zig");
const std = @import("std");
const errors = @import("errors.zig");
const artboard = @import("Artboard.zig");
const rive = @import("rive.zig");

value: *c.Rive_File,

const ImportResult = error{
    unsupported_version,
    malformed,
};

//TODO: provide higher level databinding functions

pub fn import(data: [:0]const u8, factory: anytype) !@This() {
    const c_factory = factory.value;
    const c_out: c.Rive_ImportResult = 0;

    // const span: []const u8 = std.mem.span(data);

    const ret = c.rive_file_import(data, data.len, @ptrCast(c_factory), c_out);

    if (c_out == c.RIVE_IMPORT_MALFORMED) {
        return ImportResult.malformed;
    } else if (c_out == c.RIVE_IMPORT_UNSUPPORTED_VERSION) {
        return ImportResult.unsupported_version;
    }

    return .{ .value = try errors.wrapNull(*c.Rive_File, ret) };
}

pub inline fn artboardDefault(self: @This()) !artboard.ArtboardInstance {
    return .{ .value = try errors.wrapNull(
        *c.Rive_ArtboardInstance,
        c.rive_file_artboardDefault(self.value),
    ) };
}

pub inline fn createDefaultViewModelInstance(self: @This(), ab: rive.artboard.ArtboardInstance) !rive.ViewModelInstance {
    const ret = c.rive_createDefaultViewModelInstanceFromArtboard(self.value, ab.value);
    if (ret) |vmi| {
        return .{ .value = vmi };
    } else {
        return error.CouldNotCreateDefaultViewModelInstance;
    }
}

pub inline fn createViewModelInstance(self: @This(), name: [:0]const u8) !rive.ViewModelInstance {
    const ret = c.rive_createViewModelInstance(self.value, name);
    if (ret) |vmi| {
        return .{ .value = vmi };
    } else {
        return error.CouldNotCreateViewModelInstance;
    }
}
