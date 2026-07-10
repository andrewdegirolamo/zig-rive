const std = @import("std");
const Io = std.Io;
const c = @import("c");
const sdl3 = @import("sdl3");
const objc = @import("objc");
const metal = objc.metal;
const rive = @import("rive");

var quit = std.atomic.Value(bool).init(false);

pub fn main() !void {

    //initialize SDL
    try sdl3.init(.{ .video = true });
    defer sdl3.shutdown();

    const window = try sdl3.video.Window.init("riveTest", 640, 480, .{ .resizable = true, .metal = true, .high_pixel_density = true });

    // Specific steps for metal, eventually add support for more APIs
    const mtlDevice = metal.createSystemDefaultDevice() orelse @panic("metal device couldn't be created");

    const window_props = try window.getProperties();
    const ns_window: *objc.app_kit.Window = @ptrCast(window_props.cocoa_window.?.value.?);

    //could I move this inside of metal impl?
    const metal_view = sdl3.MetalView.init(window) orelse @panic("couldn't create metal view");
    const metal_layer = metal_view.getLayer() orelse @panic("couldn't get metal layer");

    var metal_impl = try rive.MetalImpl.init(mtlDevice, metal_layer);

    //Render on a different thread to get around SDL's event polling freezing while live-resizing

    const renderingThread = try std.Thread.spawn(.{}, riveThread, .{
        ns_window,
        &metal_impl,
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
            .mouse_button_down => {
                // stateMachine.pointerDown(event.mouse_button_down.x, event.mouse_button_down.y);
            },
            .mouse_button_up => {
                // stateMachine.pointerUp(event.mouse_button_up.x, event.mouse_button_up.y);
            },
            .mouse_motion => {},
            else => {},
        }
    }
    renderingThread.join();
    window.deinit();
}

fn riveThread(
    window: ?*objc.app_kit.Window,
    metal_impl: *rive.MetalImpl,
) !void {
    const riv = @embedFile("lp_level_editor.riv");
    const file = try rive.File.import(riv, metal_impl.renderContext);

    const artboard = try file.artboardDefault();

    //just for testing
    const SMcount = artboard.stateMachineCount();
    std.debug.print("state machine count: {d}\n", .{SMcount});

    const state_machine = try artboard.defaultStateMachine();

    const renderer = try metal_impl.renderContext.makeRenderer();

    // bind default view model instance to artboard. if one exists
    if (file.createDefaultViewModelInstance(artboard)) |vmi| {
        state_machine.bindViewModelInstance(vmi);
    } else |err| {
        std.debug.print("error getting view model from file :{} \n", .{err});
    }

    var last_ticks = sdl3.timer.getMillisecondsSinceInit();
    // number_write.setValue(10);
    while (!quit.load(.monotonic)) {
        const pool = objc.objc.autoreleasePoolPush();
        //calculate delta time
        const new_ticks = sdl3.timer.getMillisecondsSinceInit();
        const dt = new_ticks - last_ticks;
        last_ticks = new_ticks;
        const dtFloat: f32 = @floatFromInt(dt);

        //get pixel density from macos window backing for retina displays
        const pixelDensity: f32 = @floatCast(window.?.backingScaleFactor());

        const width_f, const height_f = try metal_impl.beginFrame();

        //set artboard width and height to match rener target size
        artboard.setWidth(width_f / pixelDensity);
        artboard.setHeight(height_f / pixelDensity);

        renderer.save();
        renderer.DPIScale(pixelDensity);
        state_machine.advanceAndApply(dtFloat / 1000); // this is where trigger callbacks get called
        state_machine.draw(renderer);
        renderer.restore();
        try metal_impl.endFrame();
        objc.objc.autoreleasePoolPop(pool);
    }
}
