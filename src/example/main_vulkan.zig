const std = @import("std");
const builtin = @import("builtin");
const sdl3 = @import("sdl3");
const rive = @import("rive");

var quit = std.atomic.Value(bool).init(false);

pub fn main() !void {
    try sdl3.init(.{ .video = true });
    defer sdl3.shutdown();

    if (builtin.os.tag == .macos) {
        sdl3.vulkan.loadLibrary(null) catch try sdl3.vulkan.loadLibrary("/opt/homebrew/lib/libvulkan.dylib");
    }

    const window = try sdl3.video.Window.init("riveTest (Vulkan)", 640, 480, .{ .resizable = true, .vulkan = true, .high_pixel_density = true });

    var vulkan_impl = try rive.VulkanImpl.init(try sdl3.vulkan.getInstanceExtensions());

    const surface = try sdl3.vulkan.Surface.init(window, @ptrCast(@alignCast(vulkan_impl.vkInstance())), null);
    try vulkan_impl.initSwapchain(surface.surface);

    const renderingThread = try std.Thread.spawn(.{}, riveThread, .{ window, &vulkan_impl });

    while (!quit.load(.monotonic)) {
        const event = try sdl3.events.waitAndPop();
        switch (event) {
            .quit => quit.store(true, .monotonic),
            .terminating => quit.store(true, .monotonic),
            else => {},
        }
    }
    renderingThread.join();
    window.deinit();
}

fn riveThread(window: sdl3.video.Window, vulkan_impl: *rive.VulkanImpl) !void {
    const riv = @embedFile("fuecoco.riv");
    const file = try rive.File.import(riv, vulkan_impl.renderContext);

    const artboard = try file.artboardDefault();
    const state_machine = try artboard.defaultStateMachine();
    const renderer = try vulkan_impl.renderContext.makeRenderer();

    if (file.createDefaultViewModelInstance(artboard)) |vmi| {
        state_machine.bindViewModelInstance(vmi);
    } else |err| {
        std.debug.print("error getting view model from file :{} \n", .{err});
    }

    var last_ticks = sdl3.timer.getMillisecondsSinceInit();
    while (!quit.load(.monotonic)) {
        const new_ticks = sdl3.timer.getMillisecondsSinceInit();
        const dt = new_ticks - last_ticks;
        last_ticks = new_ticks;
        const dtFloat: f32 = @floatFromInt(dt);

        const pixelDensity = window.getPixelDensity() catch 1;

        const width_f, const height_f = try vulkan_impl.beginFrame();
        artboard.setWidth(width_f / pixelDensity);
        artboard.setHeight(height_f / pixelDensity);

        renderer.save();
        renderer.DPIScale(pixelDensity);
        state_machine.advanceAndApply(dtFloat / 1000);
        state_machine.draw(renderer);
        renderer.restore();
        try vulkan_impl.endFrame();
    }
}
