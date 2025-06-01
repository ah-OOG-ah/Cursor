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
const root = @import("root.zig");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const SIZE = 512;
    var noise: [SIZE * 1 * SIZE]f64 = undefined;

    root.populateNoiseArray(@ptrCast(&noise),
        0.2, 0.1, 0.0,
        SIZE, 1, SIZE,
        0.1, 0.1, 0.1,
        1.0, 1337);

    for (0..(noise.len/8)) |i| {
        try stdout.print("0x{x:0>2} ", .{i});
        for (0..8) |ii| {
            try stdout.print(" {d: >5.2}", .{ noise[i * 8 + ii] });
        }
        try stdout.print("\n", .{});
    }

    try bw.flush(); // don't forget to flush!
}
