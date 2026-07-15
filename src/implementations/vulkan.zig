const c = @import("c");
const rive = @import("../rive.zig");

const VulkanImplementation = @This();

impl: *c.Rive_VulkanImpl,
renderContext: rive.gpu.RenderContext,

pub fn init(instance_extensions: []const [*:0]const u8) !VulkanImplementation {
    const impl = c.rive_vulkanInit(
        @ptrCast(instance_extensions.ptr),
        @intCast(instance_extensions.len),
    ) orelse return error.CouldNotCreateVulkanContext;

    return .{
        .impl = impl,
        .renderContext = .{ .value = c.rive_vulkanGetRenderContext(impl).? },
    };
}

pub fn vkInstance(self: VulkanImplementation) *anyopaque {
    return c.rive_vulkanGetVkInstance(self.impl).?;
}

pub fn initSwapchain(self: *VulkanImplementation, vk_surface: ?*anyopaque) !void {
    if (!c.rive_vulkanInitSwapchain(self.impl, vk_surface)) {
        return error.CouldNotCreateSwapchain;
    }
}

pub fn beginFrame(self: *VulkanImplementation) !struct { f32, f32 } {
    var width: u32 = 0;
    var height: u32 = 0;
    if (!c.rive_vulkanBeginFrame(self.impl, &width, &height)) {
        return error.NoSwapchain;
    }
    self.renderContext.beginFrame(.{
        .render_target_width = width,
        .render_target_height = height,
        .clear_color = 0xffffff,
    });
    return .{ @floatFromInt(width), @floatFromInt(height) };
}

pub fn endFrame(self: VulkanImplementation) !void {
    c.rive_vulkanFlushAndPresent(self.impl);
}

pub fn deinit(self: VulkanImplementation) !void {
    c.rive_vulkanFree(self.impl);
}
