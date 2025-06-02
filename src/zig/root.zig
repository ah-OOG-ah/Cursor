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
    xOffset: f64, yOffset: f64, zOffset: f64,
    xSize: i32, ySize: i32, zSize: i32,
    xScale: f64, yScale: f64, zScale: f64,
    noiseScale: f64, seed: i64) void {
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
                const bidx = py + px * yMax + pz * xMax * yMax;

                buffer[bidx] = opensimplex.noise3_ImproveXZ(seed, fx, fy, fz) * noiseScale;
            }
        }
    }
}

// Theoretically caps out for f64/i64 on AVX-512
const VLEN = 2;
const VF64: type = @Vector(VLEN, f64);

pub export fn lazy_populateNoiseArray(
    noiseArray: [*]f64,
    xOffset: f64, yOffset: f64, zOffset: f64,
    xSize: i32, ySize: i32, zSize: i32,
    xScale: f64, yScale: f64, zScale: f64,
    noiseScale: f64, seed: i64) void {
    @setFloatMode(.optimized);
    const bLen = @as(usize, @intCast(xSize * ySize * zSize));
    const vbLen = bLen / VLEN;
    var buffer = noiseArray[0..bLen];

    var px: usize = 0;
    var py: usize = 0;
    var pz: usize = 0;

    for (0..vbLen) |i| {

        var fxs: VF64 = undefined;
        var fys: VF64 = undefined;
        var fzs: VF64 = undefined;
        for (0..VLEN) |ii| {
            fxs[ii] = @as(f64, @floatFromInt(px)) * xScale + xOffset;
            fys[ii] = @as(f64, @floatFromInt(py)) * yScale + yOffset;
            fzs[ii] = @as(f64, @floatFromInt(pz)) * zScale + zOffset;

            py += 1;
            if (py > ySize) {
                py = 0; pz += 1;
                if (pz > zSize) {
                    pz = 0;
                    px += 1;
                }
            }
        }

        // Imitate Minecraft's lazy noise, and just scale up the old one
        // Mix up the seed every 0.5 in the y, roughly, again to imitate MC
        const tys = fys * @as(VF64, @splat(2));
        var extraScale = tys - @floor(tys); // map y value to -1, 1, doubling so that -0.49 maps to -.98

        // invert if negative, now it's 0, 1
        extraScale = @select(f64, extraScale < @as(VF64, @splat(0)), extraScale + @as(VF64, @splat(1)), extraScale);
        extraScale = @as(VF64, @splat(1)) + extraScale * @as(VF64, @splat(0.5)); // lerp the extra scale from 1 to 1.5 based on this

        // Add 1 to the seed for every .5 bump in the y
        const ftys = @floor(tys);
        for (0..VLEN) |ii| {
            buffer[i * VLEN + ii] = opensimplex.noise2(seed +% @as(i64, @intFromFloat(ftys[ii])) *% 87178291199, fxs[ii], fzs[ii]) * noiseScale * extraScale[ii];
        }
    }

    const remaining = bLen % VLEN;
    for ((bLen - remaining)..bLen) |i| {

        const fx = @as(f64, @floatFromInt(px)) * xScale + xOffset;
        const fy = @as(f64, @floatFromInt(py)) * yScale + yOffset;
        const fz = @as(f64, @floatFromInt(pz)) * zScale + zOffset;

        // Imitate Minecraft's lazy noise, and just scale up the old one
        // Mix up the seed every 0.5 in the y, roughly, again to imitate MC
        const ty = fy * 2;
        var extraScale = ty - @floor(ty); // map y value to -1, 1, doubling so that -0.49 maps to -.98
        if (extraScale < 0) extraScale += 1; // invert if negative, now it's 0, 1
        extraScale = 1.0 + extraScale * 0.5; // lerp the extra scale from 1 to 1.5 based on this

        // Add 1 to the seed for every .5 bump in the y
        buffer[i] = opensimplex.noise2(seed +% @as(i64, @intFromFloat(@floor(ty))) *% 87178291199, fx, fz) * noiseScale * extraScale;

        py += 1;
        if (py > ySize) {
            py = 0; px += 1;
            if (px > xSize) {
                px = 0;
                pz += 1;
            }
        }
    }
}

pub export fn FNL_populateNoiseArray(
    noiseArray: [*]f64,
    xOffset: f64, yOffset: f64, zOffset: f64,
    xSize: i32, ySize: i32, zSize: i32,
    xScale: f64, yScale: f64, zScale: f64,
    noiseScale: f64, seed: i64) void {
    @setFloatMode(.optimized);
    const bLen = @as(usize, @intCast(xSize * ySize * zSize));
    var buffer = noiseArray[0..bLen];

    const xMax = @as(usize, @intCast(xSize));
    const yMax = @as(usize, @intCast(ySize));
    const zMax = @as(usize, @intCast(zSize));

    const NoiseGen = fastnoiselite.Noise(f64);
    const generator: NoiseGen = .{
        .seed = @truncate(seed),
        .frequency = 1,
        .noise_type = .simplex,
        .octaves = 1,
    };

    for (0..xMax) |px| {
        const fx = @as(f64, @floatFromInt(px)) * xScale + xOffset;

        for (0..yMax) |py| {
            const fy = @as(f64, @floatFromInt(py)) * yScale + yOffset;

            for (0..zMax) |pz| {
                const fz = @as(f64, @floatFromInt(pz)) * zScale + zOffset;
                const bidx = py + px * yMax + pz * xMax * yMax;

                buffer[bidx] = generator.genNoise3D(fx, fy, fz) * noiseScale;
            }
        }
    }
}
