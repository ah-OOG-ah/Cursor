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

    const SIZE = 4;
    var noise: [SIZE * SIZE * SIZE]f64 = undefined;

    root.populateNoiseArray(@ptrCast(&noise), 0.2, 0.1, 0.0, SIZE, SIZE, SIZE, 0.1, 0.1, 0.1, 1.0, 1337);

    for (0..(noise.len/8)) |i| {
        try stdout.print("0x{x:0>2} ", .{i});
        for (0..8) |ii| {
            try stdout.print(" {d: >5.2}", .{ noise[i * 8 + ii] });
        }
        try stdout.print("\n", .{});
    }

    try bw.flush(); // don't forget to flush!
}
