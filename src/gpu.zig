const c = @import("c");
const Factory = @import("Factory.zig");
const errors = @import("errrors.zig");
const rive = @import("rive.zig");

pub const RenderContext = struct {
    value: *c.Rive_RenderContext,

    pub const FrameDescriptor = c.Rive_FrameDescriptor;

    pub const FlushResources = extern struct {
        //TODO: make render_target accept rive render target, probably
        render_target: *anyopaque,
        external_command_buffer: *anyopaque,
    };

    //TODO: make this into an interface
    pub inline fn makeRenderTargetMetal(self: @This(), width: u32, height: u32) !rive.RenderTargetMetal {
        return .{ .value = try errors.wrapNull(
            *c.Rive_RenderTargetMetal,
            c.rive_getMetalRenderTarget(self.value, width, height),
        ) };
    }
    pub inline fn makeRenderer(self: @This()) !rive.RiveRenderer {
        return .{ .value = try errors.wrapNull(
            *c.Rive_RiveRenderer,
            c.rive_getRendererFromContext(self.value),
        ) };
    }
    pub inline fn beginFrame(self: @This(), fd: FrameDescriptor) void {
        c.rive_contextBeginFrame(self.value, fd);
    }
    pub fn flush(self: @This(), to_flush: FlushResources) void {
        var fr: c.Rive_FlushResources = .{
            .externalCommandBuffer = to_flush.external_command_buffer,
            .renderTarget = @ptrCast(to_flush.render_target),
        };
        c.rive_contextFlush(self.value, &fr);
    }
};

pub const ContextOptions = struct {};

pub const RenderContextMetalImpl = struct {
    //TODO: add contextOptions

    pub fn makeContext(mtl_device: *anyopaque) !RenderContext {
        return .{ .value = try errors.wrapNull(
            *c.Rive_RenderContext,
            c.rive_MakeContextMetal(mtl_device),
        ) };
    }
};
