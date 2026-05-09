const std = @import("std");
const zcc = @import("compile_commands");

pub fn build(b: *std.Build) void {

    // make a list of targets that have include files and c source files
    var targets: std.ArrayList(*std.Build.Step.Compile) = .empty;

    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const rive = b.dependency("rive", .{});

    const mod = b.addModule("zig_rive", .{
        // .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        // .imports = &.{ .{ .name = "rive", .module = rive.module("rive_mod") }, .{ .name = "rive_renderer", .module = rive.module("rive_renderer_mod") } },
        .link_libc = true,
        .link_libcpp = true,
    });

    mod.addCSourceFile(.{ .file = b.path("src/rive.cpp") });

    const riveLib = rive.artifact("rive");
    const riveRendererLib = rive.artifact("rive_renderer");
    targets.append(b.allocator, riveLib) catch @panic("OOM");
    // targets.append(b.allocator, riveRendererLib) catch @panic("OOM");

    mod.linkLibrary(riveLib);
    mod.linkLibrary(riveRendererLib);

    const lib = b.addLibrary(.{ .name = "riveZig", .root_module = mod });

    b.installArtifact(lib);

    //step for generating compile commands
    _ = zcc.createStep(b, "cdb", targets.toOwnedSlice(b.allocator) catch @panic("OOM"));
}
