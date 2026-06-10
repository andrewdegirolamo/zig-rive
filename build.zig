const std = @import("std");
const zcc = @import("compile_commands");

pub fn build(b: *std.Build) void {

    // make a list of targets that have include files and c source files
    var targets: std.ArrayList(*std.Build.Step.Compile) = .empty;

    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const rive = b.dependency("rive", .{
        .target = target,
        .optimize = optimize,
    });

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("src/riveWrapper.h"),
        .target = target,
        .optimize = optimize,
    });
    const c_mod = translate_c.createModule();
    c_mod.addCSourceFile(.{ .file = b.path("src/riveWrapper.cpp") });
    c_mod.addCSourceFile(.{ .file = b.path("src/metalsetup.mm") });

    const rivezig_mod = b.addModule("zig_rive", .{
        // .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        // .imports = &.{ .{ .name = "rive", .module = rive.module("rive_mod") }, .{ .name = "rive_renderer", .module = rive.module("rive_renderer_mod") } },
        .link_libc = true,
        .link_libcpp = true,
    });

    const sdl3 = b.dependency("sdl3", .{
        .target = target,
        .optimize = optimize,
    });
    //platform specific

    const objc = b.dependency("mach_objc", .{
        .target = target,
        .optimize = optimize,
    });

    const example = b.addModule("sdl_rive_example", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
        .imports = &.{
            // .{ .name = "rive", .module = mod },
            .{ .name = "sdl3", .module = sdl3.module("sdl3") },
            .{ .name = "c", .module = c_mod }, //eventually put this in mod and import mod instead
            .{ .name = "objc", .module = objc.module("mach-objc") },
        },
    });

    const exe = b.addExecutable(.{
        .name = "Rive SDL Example",
        .root_module = example,
    });
    b.installArtifact(exe);

    const riveLib = rive.artifact("rive");
    const riveRendererLib = rive.artifact("rive_renderer");
    // targets.append(b.allocator, riveLib) catch @panic("OOM");
    // targets.append(b.allocator, riveRendererLib) catch @panic("OOM");

    rivezig_mod.linkLibrary(riveLib);
    // mod.linkFramework("Metal", .{});
    rivezig_mod.linkLibrary(riveRendererLib);
    c_mod.linkLibrary(riveLib);
    c_mod.linkLibrary(riveRendererLib);
    c_mod.linkFramework("Metal", .{});
    c_mod.linkFramework("Foundation", .{});
    const lib = b.addLibrary(.{ .name = "riveZig", .root_module = rivezig_mod });

    targets.append(b.allocator, lib) catch @panic("OOM");

    //step for generating compile commands
    _ = zcc.createStep(b, "cdb", targets.toOwnedSlice(b.allocator) catch @panic("OOM"));

    //add run step
    const run_exe = b.addRunArtifact(exe);

    const run = b.step("run", "run sdl3 example");
    run.dependOn(&run_exe.step);
}
