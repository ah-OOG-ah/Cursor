const std = @import("std");
const root = @import("root.zig");

fn Result(comptime t: anytype) type {
    return struct {
        raw: []u8,
        ret: t
    };
}

fn alloc_f64JArray(allocator: std.mem.Allocator, size: usize) error{OutOfMemory}!Result(*root.f64JArray) {
    const raw = try allocator.alignedAlloc(
        u8, @alignOf(root.f64JArray), @sizeOf(root.f64JArray) - @sizeOf(f64) + size * @sizeOf(f64));


    @memset(raw, 0);
    const ret = @as(*root.f64JArray, @ptrCast(raw));
    ret.*.size = @intCast(size);
    return .{ .raw = raw, .ret = ret };
}

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

    const allocation = try alloc_f64JArray(allocator, 256);
    defer allocator.free(allocation.raw);
    const c2_ptr = allocation.ret;

    root.populateNoiseArray(c2_ptr, 1.0, 10.0, 0.0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0);
    const cptr = root.get_buf(c2_ptr);

    for (0..(c2_ptr.size/8)) |i| {
        try stdout.print("0x{x:0>2} ", .{i});
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
