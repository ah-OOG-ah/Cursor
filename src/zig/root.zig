const std = @import("std");
const testing = std.testing;
const opensimplex = @import("opensimplex.zig");

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
    noiseScale: f64, seed: i64) void {
    @setFloatMode(.optimized);
    var buffer = get_buf(noiseArray);

    if (xSize * ySize * zSize != noiseArray.size) return;
    const xMax = @as(usize, @intCast(xSize));
    const yMax = @as(usize, @intCast(ySize));
    const zMax = @as(usize, @intCast(zSize));

    for (0..xMax) |px| {
        const fx = @as(f64, @floatFromInt(px)) * xScale + xOffset;

        for (0..yMax) |py| {
            const fy = @as(f64, @floatFromInt(py)) * yScale + yOffset;

            for (0..zMax) |pz| {
                const fz = @as(f64, @floatFromInt(pz)) * zScale + zOffset;
                const bidx = pz * xMax * yMax + py * xMax + px;

                buffer[bidx] = opensimplex.noise3_ImproveXZ(seed, fx, fy, fz) * noiseScale;
            }
        }
    }
}
