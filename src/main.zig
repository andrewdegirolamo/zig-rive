const std = @import("std");
const Io = std.Io;
const c = @import("c");

pub fn main() void {
    const riv = @embedFile("fuecoco.riv");
    var result: c.Rive_ImportResult = undefined;
    const factory: *c.Rive_Factory = c.rive_factory_createHeadless().?;

    const file = c.rive_file_import(riv, riv.len, factory, &result);
    const artboard = c.rive_file_artboardDefault(file);

    const SMcount = c.rive_artboard_stateMachineCount(artboard);
    std.debug.print("state machine count: {d}\n", .{SMcount});
}
