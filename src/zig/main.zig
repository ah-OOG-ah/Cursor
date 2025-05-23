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

    var tmp = root.FakeF64JArray { .buffer = undefined };
    @memset(&tmp.buffer, 0);

    const c2_ptr: [*c]root.f64JArray = @ptrCast(&tmp);
    root.populateNoiseArray(c2_ptr, 1.0, 10.0, 0.0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0);
    const cptr = @as([*c]f64, @ptrCast(c2_ptr)) + 2;

    for (0..(tmp.size/8)) |i| {
        try stdout.print("{} ", .{i});
        for (0..8) |ii| {
            try stdout.print(" {}", .{ cptr[i * 8 + ii] });
            // try stdout.print(" 0x{x:0>4}", .{ cptr[i * 8 + ii] });
        }
        try stdout.print("\n", .{});
    }

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
