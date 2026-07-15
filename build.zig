const std = @import("std");
const zcc = @import("compile_commands");

pub fn build(b: *std.Build) void {

    //TODO: Cleanup

    // make a list of targets that have include files and c source files
    var targets: std.ArrayList(*std.Build.Step.Compile) = .empty;

    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const rive_dep = b.dependency("rive", .{
        .target = target,
        .optimize = optimize,
    });

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("src/c-api/riveWrapper.h"),
        .target = target,
        .optimize = optimize,
    });
    const c_mod = translate_c.createModule();
    c_mod.addCSourceFile(.{ .file = b.path("src/c-api/riveWrapper.cpp") });
    c_mod.addCSourceFile(.{ .file = b.path("src/c-api/metalsetup.mm") });
    c_mod.addCMacro("WITH_RIVE_TOOLS", "1");

    const vulkan = b.option(bool, "vulkan", "build the vulkan example (requires a vulkan-enabled rive-zig-build)") orelse false;

    if (vulkan) {
        c_mod.addCSourceFile(.{ .file = b.path("src/c-api/vulkansetup.cpp") });
        c_mod.addCMacro("RIVE_VULKAN", "");
        c_mod.addIncludePath(rive_dep.builder.dependency("rive", .{}).path("renderer/rive_vk_bootstrap/include"));
        c_mod.addIncludePath(rive_dep.builder.dependency("Vulkan-Headers", .{}).path("include"));
    }

    const objc = b.dependency("mach_objc", .{
        .target = target,
        .optimize = optimize,
    });

    const rive = b.addModule("zig_rive", .{
        .root_source_file = b.path("src/rive.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
        .imports = &.{
            .{ .name = "c", .module = c_mod },
            .{ .name = "objc", .module = objc.module("mach-objc") },
        }, //eventually put this in mod and import mod instead
    });

    const rive_lib = b.addLibrary(.{
        .name = "rive",
        .root_module = rive,
    });

    const sdl3 = b.dependency("sdl3", .{
        .target = target,
        .optimize = optimize,
    });

    //platform specific

    const example = b.addModule("sdl_rive_example", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/example/main.zig"),
        .imports = &.{
            // .{ .name = "rive", .module = mod },
            .{ .name = "sdl3", .module = sdl3.module("sdl3") },
            .{ .name = "c", .module = c_mod }, //eventually put this in mod and import mod instead
            .{ .name = "rive", .module = rive },
            .{ .name = "objc", .module = objc.module("mach-objc") },
        },
    });

    const exe = b.addExecutable(.{
        .name = "Rive SDL Example",
        .root_module = example,
    });
    b.installArtifact(exe);

    const rive_cpp_lib = rive_dep.artifact("rive");
    const riveRenderer_lib = rive_dep.artifact("rive_renderer");
    // targets.append(b.allocator, riveLib) catch @panic("OOM");
    // targets.append(b.allocator, riveRendererLib) catch @panic("OOM");

    rive.linkLibrary(rive_cpp_lib);
    // mod.linkFramework("Metal", .{});
    rive.linkLibrary(riveRenderer_lib);
    c_mod.linkLibrary(rive_cpp_lib);
    c_mod.linkLibrary(riveRenderer_lib);
    c_mod.linkFramework("Metal", .{});
    c_mod.linkFramework("Foundation", .{});
    const lib = b.addLibrary(.{ .name = "riveZig", .root_module = c_mod });

    targets.append(b.allocator, lib) catch @panic("OOM");

    //step for generating compile commands
    _ = zcc.createStep(b, "cdb", targets.toOwnedSlice(b.allocator) catch @panic("OOM"));

    //add run step
    const run_exe = b.addRunArtifact(exe);

    const run = b.step("run", "run sdl3 example");
    run.dependOn(&run_exe.step);

    if (vulkan) {
        const example_vulkan = b.addModule("sdl_rive_example_vulkan", .{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("src/example/main_vulkan.zig"),
            .imports = &.{
                .{ .name = "sdl3", .module = sdl3.module("sdl3") },
                .{ .name = "c", .module = c_mod },
                .{ .name = "rive", .module = rive },
            },
        });

        const exe_vulkan = b.addExecutable(.{
            .name = "Rive SDL Vulkan Example",
            .root_module = example_vulkan,
        });
        b.installArtifact(exe_vulkan);

        const run_vulkan = b.step("run-vulkan", "run sdl3 vulkan example");
        run_vulkan.dependOn(&b.addRunArtifact(exe_vulkan).step);
    }

    //ZLS check step for build-on-save errors
    const exe_check = b.addExecutable(.{
        .name = "foo",
        .root_module = example,
    });

    //generate documentation

    const install_docs = b.addInstallDirectory(.{
        .source_dir = rive_lib.getEmittedDocs(),
        .install_dir = .{ .prefix = {} },
        .install_subdir = "docs",
    });

    const docs_step = b.step("docs", "Generate documentation for Zig-Rive");

    docs_step.dependOn(&install_docs.step);

    const check = b.step("check", "Check if foo compiles");
    check.dependOn(&exe_check.step);
}
