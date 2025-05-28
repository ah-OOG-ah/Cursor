const std = @import("std");
const root = @import("root.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        // can't try in defer as defer is executed after we return
        if (deinit_status == .leak) @panic("WARNING: Memory leaked!");
    }

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const SIZE = 4;
    const a = root.alloc_f64JArray(allocator, SIZE * SIZE * SIZE);
    if (a == null) {
        return;
    }

    const allocation = a.?;
    defer allocator.free(allocation.raw);
    const c2_ptr = allocation.ret;

    root.populateNoiseArray(c2_ptr, 0.2, 0.1, 0.0, SIZE, SIZE, SIZE, 0.1, 0.1, 0.1, 1.0, 1337);
    const cptr = root.get_buf(c2_ptr);

    for (0..(c2_ptr.size/8)) |i| {
        try stdout.print("0x{x:0>2} ", .{i});
        for (0..8) |ii| {
            try stdout.print(" {d: >5.2}", .{ cptr[i * 8 + ii] });
            // try stdout.print(" 0x{x:0>4}", .{ cptr[i * 8 + ii] });
        }
        try stdout.print("\n", .{});
    }

    try bw.flush(); // don't forget to flush!
}
