const c = @import("c");

value: *c.Rive_RiveRenderer,

pub inline fn save(self: @This()) void {
    c.rive_rendererSave(self.value);
}
pub inline fn restore(self: @This()) void {
    c.rive_rendererRestore(self.value);
}

///Temporary until I add renderer transform functions
pub inline fn DPIScale(self: @This(), scale: f32) void {
    c.rive_rendererDPIScale(self.value, scale);
}
pub inline fn free(self: @This()) void {
    c.rive_freeRenderer(self.value);
}
