const std = @import("std");
const testing = std.testing;

pub const f64JArray = extern struct {
    _opauqe1: u64,
    _opauqe2: u32,
    size: u32,
    elements: f64 // note: this is an array of size length
};

pub fn get_buf(arr: *f64JArray) []f64 {
    return @as([*]f64, @ptrCast(&arr.elements))[0..arr.size];
}

pub export fn populateNoiseArray(
    noiseArray: *f64JArray,
    xOffset: f64, yOffset: f64, zOffset: f64,
    xSize: i32, ySize: i32, zSize: i32,
    xScale: f64, yScale: f64, zScale: f64,
    noiseScale: f64) void {
    var buffer = get_buf(noiseArray);

    if (xSize * ySize * zSize != noiseArray.size) return;

    for (0..noiseArray.*.size) |i| {
        buffer[i] = xOffset + yOffset + zOffset + @as(f64, @floatFromInt(xSize + ySize + zSize)) + xScale + yScale + zScale + noiseScale;
    }
}
