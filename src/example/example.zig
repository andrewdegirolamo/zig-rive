const std = @import("std");
const Io = std.Io;
const c = @import("c");
const sdl3 = @import("sdl3");
const objc = @import("objc");
const metal = objc.metal;
const rive = @import("rive");

var quit = std.atomic.Value(bool).init(false);

pub fn main() !void {
    //TODO fix memory leak, probably get rid of autoreleasepool
    //TODO start writing zig wrappper

    const riv = @embedFile("fuecoco.riv");

    //initialize sdl
    try sdl3.init(.{ .video = true });
    defer sdl3.shutdown();

    const window = try sdl3.video.Window.init("riveTest", 640, 480, .{ .resizable = true, .metal = true, .high_pixel_density = true });

    // eventually make this separate for each platform
    const mtlDevice = metal.createSystemDefaultDevice() orelse @panic("metal device couldn't be created");
    const renderContext = try rive.gpu.RenderContextMetalImpl.makeContext(mtlDevice);

    const file = try rive.File.import(riv, renderContext);
    //

    const artboard = try file.artboardDefault();

    //just for testing
    const SMcount = artboard.stateMachineCount();
    std.debug.print("state machine count: {d}\n", .{SMcount});

    const stateMachine = try artboard.defaultStateMachine();

    const windowProps = try window.getProperties();
    const nsWindow: *objc.app_kit.Window = @ptrCast(windowProps.cocoa_window.?.value.?);
    // const nsView = nsWindow.*.contentView().?;
    // nsView.setWantsLayer(true);

    const width, const height = try window.getSize();
    var renderTarget = try renderContext.makeRenderTargetMetal(@intCast(width), @intCast(height));
    const queue = mtlDevice.newCommandQueue() orelse @panic("null");
    const renderer = try renderContext.makeRenderer();

    const metalView = sdl3.MetalView.init(window);
    const metalLayer = metalView.?.getLayer();
    const swapchain: *objc.quartz_core.MetalLayer = @ptrCast(metalLayer);

    swapchain.setDevice(mtlDevice);
    swapchain.setPixelFormat(objc.metal.PixelFormatBGRA8Unorm);
    swapchain.setDisplaySyncEnabled(true); //Vsync

    // nsView.setLayer(@ptrCast(swapchain));

    //Render on a different thread to get around SDL's event polling freezing while live-resizing

    const renderingThread = try std.Thread.spawn(.{}, riveRender, .{
        swapchain,
        queue,
        &renderTarget,
        nsWindow,
        stateMachine,
        renderContext,
        renderer,
        artboard,
    });

    //run loop
    while (!quit.load(.monotonic)) {
        const event = try sdl3.events.waitAndPop();
        switch (event) {
            .quit => {
                quit.store(true, .monotonic);
            },
            .terminating => {
                quit.store(true, .monotonic);
            },
            else => {},
        }
    }
    renderingThread.join();
    renderer.free();
    window.deinit();
}

fn riveRender(
    metalLayer: *objc.quartz_core.MetalLayer,
    queue: *metal.CommandQueue,
    target: *rive.RenderTargetMetal,
    window: ?*objc.app_kit.Window,
    sm: rive.StateMachineInstance,
    renderContext: rive.gpu.RenderContext,
    renderer: rive.RiveRenderer,
    artboard: rive.artboard.ArtboardInstance,
) !void {
    var last_ticks = sdl3.timer.getMillisecondsSinceInit();
    while (!quit.load(.monotonic)) {
        const new_ticks = sdl3.timer.getMillisecondsSinceInit();
        const dt = new_ticks - last_ticks;
        last_ticks = new_ticks;
        const pool = objc.objc.autoreleasePoolPush();
        const dtFloat: f32 = @floatFromInt(dt);

        const currentFrameSurface = objc.quartz_core.MetalLayer.nextDrawable(metalLayer) orelse @panic("surface null");

        const pixelDensity: f32 = @floatCast(window.?.backingScaleFactor());

        const width_d = currentFrameSurface.texture().width();
        const height_d = currentFrameSurface.texture().height();
        const width_f: f32 = @floatFromInt(width_d);
        const height_f: f32 = @floatFromInt(height_d);

        artboard.setWidth(width_f / pixelDensity);
        artboard.setHeight(height_f / pixelDensity);

        target.* = try renderContext.makeRenderTargetMetal(@intCast(width_d), @intCast(height_d));
        target.setTargetTexture(currentFrameSurface.texture());

        renderContext.beginFrame(.{
            .render_target_width = @intCast(width_d),
            .render_target_height = @intCast(height_d),
            .clear_color = 0xffffff,
        });

        renderer.save();
        renderer.DPIScale(pixelDensity);
        sm.advanceAndApply(dtFloat / 1000);
        sm.draw(renderer);
        renderer.restore();

        const flushCommandBuffer = queue.commandBuffer().?;

        renderContext.flush(.{
            .render_target = target.value,
            .external_command_buffer = flushCommandBuffer,
        });

        flushCommandBuffer.commit();

        const presentCommandBuffer = queue.commandBuffer().?;
        presentCommandBuffer.presentDrawable(@ptrCast(currentFrameSurface));
        presentCommandBuffer.commit();
        target.setTargetTexture(null);
        presentCommandBuffer.waitUntilCompleted();
        //
        // currentFrameSurface.release();
        // flushCommandBuffer.release();
        // presentCommandBuffer.release();
        objc.objc.autoreleasePoolPop(pool);
    }
}
