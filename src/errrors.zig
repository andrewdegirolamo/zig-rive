///This code is taken from zig-sdl3 by 7Games
pub fn wrapNull(
    comptime Result: type,
    result: ?Result,
) !Result {
    if (result) |val|
        return val;
    return error.RiveNullError;
}
