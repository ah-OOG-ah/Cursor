// This file is part of Cursor - a mod that _runs_.
// Copyright (C) 2025 ah-OOG-ah
//
// Cursor is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Cursor is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");
const testing = std.testing;
const opensimplex = @import("opensimplex.zig");
const fastnoiselite = @import("fastnoiselite.zig");

fn Result(comptime T: type) type {
    return struct {
        raw: [] align(@alignOf(T)) u8,
        ret: T
    };
}

pub fn alloc_f64JArray(allocator: std.mem.Allocator, size: usize) ?Result(*f64JArray) {
    const raw = allocator.alignedAlloc(
        u8, @alignOf(f64JArray), @sizeOf(f64JArray) - @sizeOf(f64) + size * @sizeOf(f64))
    catch {
        std.log.debug("Allocation failed!", .{});
        return null;
    };

    @memset(raw, 0);
    const ret = @as(*f64JArray, @ptrCast(raw));
    ret.*.size = @intCast(size);
    return .{ .raw = raw, .ret = ret };
}

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
    noiseArray: [*]f64,
    xOffset: f32, yOffset: f32, zOffset: f32,
    xSize: i32, ySize: i32, zSize: i32,
    xScale: f32, yScale: f32, zScale: f32,
    noiseScale: f32, seed: i64) void {
    @setFloatMode(.optimized);
    const bLen = @as(usize, @intCast(xSize * ySize * zSize));
    var buffer = noiseArray[0..bLen];

    const xMax = @as(usize, @intCast(xSize));
    const yMax = @as(usize, @intCast(ySize));
    const zMax = @as(usize, @intCast(zSize));

    for (0..xMax) |px| {
        const fx = @as(f32, @floatFromInt(px)) * xScale + xOffset;

        for (0..yMax) |py| {
            const fy = @as(f32, @floatFromInt(py)) * yScale + yOffset;

            for (0..zMax) |pz| {
                const fz = @as(f32, @floatFromInt(pz)) * zScale + zOffset;
                const bidx = py + px * yMax + pz * xMax * yMax;

                buffer[bidx] = opensimplex.noise3_ImproveXZ(seed,fx, fy,fz) * noiseScale;
            }
        }
    }
}

pub export fn FNL_populateNoiseArray(
    noiseArray: [*]f64,
    xOffset: f32, yOffset: f32, zOffset: f32,
    xSize: i32, ySize: i32, zSize: i32,
    xScale: f32, yScale: f32, zScale: f32,
    noiseScale: f32, seed: i64) void {
    @setFloatMode(.optimized);
    const bLen = @as(usize, @intCast(xSize * ySize * zSize));
    var buffer = noiseArray[0..bLen];

    const xMax = @as(usize, @intCast(xSize));
    const yMax = @as(usize, @intCast(ySize));
    const zMax = @as(usize, @intCast(zSize));

    const NoiseGen = fastnoiselite.Noise(f32);
    const generator: NoiseGen = .{
        .seed = @truncate(seed),
        .frequency = 1,
        .noise_type = .simplex,
        .octaves = 1,
    };

    for (0..xMax) |px| {
        const fx = @as(f32, @floatFromInt(px)) * xScale + xOffset;

        for (0..yMax) |py| {
            const fy = @as(f32, @floatFromInt(py)) * yScale + yOffset;

            for (0..zMax) |pz| {
                const fz = @as(f32, @floatFromInt(pz)) * zScale + zOffset;
                const bidx = py + px * yMax + pz * xMax * yMax;

                buffer[bidx] = generator.genNoise3D(fx, fy,fz) * noiseScale;
            }
        }
    }
}
