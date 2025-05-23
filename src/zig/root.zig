const std = @import("std");
const testing = std.testing;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}

pub const f64JArray = extern struct {
    _opauqe1: u64,
    _opauqe2: u32,
    size: u32,
    // elements: [size]f64
};

fn get(arr: [*c]f64JArray, i: usize) f64 {
    var data_ptr: [*c]f64 = @ptrCast(arr); data_ptr += 2;
    return data_ptr[i];
}

fn set(arr: [*c]f64JArray, i: usize, val: f64) void {
    var data_ptr: [*c]f64 = @ptrCast(arr); data_ptr += 2;
    data_ptr[i] = val;
}

pub export fn populateNoiseArray(
    noiseArray: [*c]f64JArray,
    xOffset: f64, yOffset: f64, zOffset: f64,
    xSize: i32, ySize: i32, zSize: i32,
    xScale: f64, yScale: f64, zScale: f64,
    noiseScale: f64) void {
    for (0..noiseArray.*.size) |i| {
        set(noiseArray, i, xOffset + yOffset + zOffset + @as(f64, @floatFromInt(xSize + ySize + zSize)) + xScale + yScale + zScale + noiseScale);
    }
}

pub const FakeF64JArray = extern struct {
    _opauqe1: u64 = 0,
    _opauqe2: u32 = 0,
    size: u32 = 256,
    buffer: [256]u64
};


