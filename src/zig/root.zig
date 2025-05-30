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
const zbench = @import("zbench");

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
    xOffset: f64, yOffset: f64, zOffset: f64,
    xSize: i32, ySize: i32, zSize: i32,
    xScale: f64, yScale: f64, zScale: f64,
    noiseScale: f64, seed: i64, noiseOffset: f64) void {
    @setFloatMode(.optimized);
    const bLen = @as(usize, @intCast(xSize * ySize * zSize));
    var buffer = noiseArray[0..bLen];

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

    for (0..bLen) |i| {
        buffer[i] += noiseOffset;
    }
}
