const std = @import("std");
const Io = std.Io;
const c = @import("c");
const sdl3 = @import("sdl3");
const objc = @import("objc");
const metal = objc.metal;

pub fn main() !void {
    //TODO: fix text in debug/releasesafe
    //TODO fix memory leak, probably get rid of autoreleasepool
    //TODO start writing zig wrappper

    const riv = @embedFile("fuecoco.riv");

    //initialize sdl
    try sdl3.init(.{ .video = true });
    defer sdl3.shutdown();

    const window = try sdl3.video.Window.init("riveTest", 640, 480, .{ .resizable = true, .metal = true, .high_pixel_density = true });
    var quit = false;

    var result: c.Rive_ImportResult = undefined;

    // eventually make this separate for each platform
    const mtlDevice = metal.createSystemDefaultDevice() orelse @panic("null");

    const renderContext = c.rive_MakeContextMetal(mtlDevice) orelse @panic("null");
    const factory = c.rive_contextToFactory(renderContext) orelse @panic("null");

    const file = c.rive_file_import(riv, riv.len, factory, &result) orelse @panic("null");
    const artboard = c.rive_file_artboardDefault(file) orelse @panic("null");

    //just for testing
    const SMcount = c.rive_artboard_stateMachineCount(artboard);
    std.debug.print("state machine count: {d}\n", .{SMcount});
    const stateMachine = c.rive_artboard_defaultStateMachine(artboard) orelse @panic("state machine null");

    // const windowProps = try window.getProperties();
    // const nsWindow: *objc.app_kit.Window = @ptrCast(windowProps.cocoa_window.?.value.?);
    // const nsView = nsWindow.*.contentView().?;
    // nsView.setWantsLayer(true);

    const width, const height = try window.getSize();
    var renderTarget = c.rive_getMetalRenderTarget(renderContext, @intCast(width), @intCast(height));
    const queue = mtlDevice.newCommandQueue() orelse @panic("null");
    const renderer = c.rive_getRendererFromContext(renderContext);

    const metalView = sdl3.MetalView.init(window);
    const metalLayer = metalView.?.getLayer();
    const swapchain: *objc.quartz_core.MetalLayer = @ptrCast(metalLayer);

    swapchain.setDevice(mtlDevice);
    swapchain.setPixelFormat(objc.metal.PixelFormatBGRA8Unorm);
    swapchain.setDisplaySyncEnabled(true); //Vsync
    // nsView.setLayer(@ptrCast(swapchain));

    var last_ticks = sdl3.timer.getMillisecondsSinceInit();

    //run loop
    while (!quit) {
        while (sdl3.events.poll()) |event| {
            switch (event) {
                .quit => quit = true,
                .terminating => quit = true,
                else => {},
            }
        }
        //calculate delta time
        const new_ticks = sdl3.timer.getMillisecondsSinceInit();
        const dt = new_ticks - last_ticks;
        last_ticks = new_ticks;

        try riveRender(swapchain, queue, &renderTarget, window, stateMachine, renderContext, renderer, dt, artboard);
    }
    defer window.deinit();
    c.rive_freeRenderer(renderer);
}

fn riveRender(
    metalLayer: *objc.quartz_core.MetalLayer,
    queue: *metal.CommandQueue,
    target: *?*c.Rive_RenderTargetMetal,
    window: sdl3.video.Window,
    sm: *c.Rive_StateMachineInstance,
    renderContext: *c.Rive_RenderContext,
    renderer: ?*c.Rive_RiveRenderer,
    dt: u64,
    artboard: *c.Rive_ArtboardInstance,
) !void {
    const pool = objc.objc.autoreleasePoolPush();
    //advance the state machine
    const dtFloat: f32 = @floatFromInt(dt);
    // std.debug.print("dt: {d}", .{dt});

    const pixelDensity = try window.getPixelDensity();

    const width_p, const height_p = try window.getSizeInPixels();
    const width, const height = try window.getSize();

    c.rive_artboardSetWidth(artboard, @floatFromInt(width));
    c.rive_artboardSetHeight(artboard, @floatFromInt(height));
    target.* = c.rive_getMetalRenderTarget(renderContext, @intCast(width_p), @intCast(height_p)) orelse @panic("null");
    // if (c.rive_renderTargetGetWidth(target.*) != width or c.rive_renderTargetGetHeight(target.*) != height) {
    //     //window size has changed
    //
    // }
    c.rive_SMIadvanceAndApply(sm, dtFloat / 1000);

    var frame = c.Rive_FrameDescriptor{
        .render_target_width = @intCast(width_p),
        .render_target_height = @intCast(height_p),
        .clear_color = 0xffffff,
    };

    c.rive_contextBeginFrame(renderContext, &frame);

    c.rive_rendererSave(renderer);
    c.rive_rendererDPIScale(renderer, pixelDensity);
    c.rive_SMIdraw(sm, renderer);
    c.rive_rendererRestore(renderer);

    const currentFrameSurface = objc.quartz_core.MetalLayer.nextDrawable(metalLayer) orelse @panic("surface null");

    c.rive_setMetalTargetTexture(target.*, currentFrameSurface.texture());
    const flushCommandBuffer = queue.commandBuffer().?;

    var flush = c.Rive_FlushResources{
        .renderTarget = @ptrCast(target.*),
        .externalCommandBuffer = flushCommandBuffer,
    };

    c.rive_contextFlush(renderContext, &flush);
    flushCommandBuffer.commit();

    const presentCommandBuffer = queue.commandBuffer().?;
    presentCommandBuffer.presentDrawable(@ptrCast(currentFrameSurface));
    presentCommandBuffer.commit();
    c.rive_setMetalTargetTexture(target.*, null);
    presentCommandBuffer.waitUntilCompleted();
    //
    // currentFrameSurface.release();
    // flushCommandBuffer.release();
    // presentCommandBuffer.release();
    objc.objc.autoreleasePoolPop(pool);
}
