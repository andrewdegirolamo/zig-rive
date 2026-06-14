//! File rive!
const c = @import("c");
const Factory = @import("Factory.zig");
const std = @import("std");
const errors = @import("errrors.zig");
const artboard = @import("Artboard.zig");

value: *c.Rive_File,

const ImportResult = error{
    unsupported_version,
    malformed,
};

pub fn import(data: [:0]const u8, factory: anytype) !@This() {
    const c_factory = factory.value;
    const c_out: c.Rive_ImportResult = 0;

    // const span: []const u8 = std.mem.span(data);

    std.debug.print("file: {s}", .{data});

    const ret = c.rive_file_import(data, data.len, @ptrCast(c_factory), c_out);

    if (c_out == c.RIVE_IMPORT_MALFORMED) {
        return ImportResult.malformed;
    } else if (c_out == c.RIVE_IMPORT_UNSUPPORTED_VERSION) {
        return ImportResult.unsupported_version;
    }

    return .{ .value = try errors.wrapNull(*c.Rive_File, ret) };
}

pub fn artboardDefault(self: @This()) !artboard.ArtboardInstance {
    return .{ .value = try errors.wrapNull(
        *c.Rive_ArtboardInstance,
        c.rive_file_artboardDefault(self.value),
    ) };
}
