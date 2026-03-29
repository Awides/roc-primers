const std = @import("std");

// Roc ABI: main_for_host is provided by platform.roc
extern fn roc__main_for_host_1_exposed() callconv(.C) void;

pub fn main() !void {
    std.debug.print("Zig: Calling Roc...\n", .{});
    roc__main_for_host_1_exposed();
    std.debug.print("Zig: Roc finished.\n", .{});
}

// Roc runtime hooks (minimal for this example)
export fn roc_alloc(size: usize, alignment: u32) callconv(.C) ?*anyopaque {
    _ = alignment;
    const ptr = std.heap.c_allocator.alloc(u8, size) catch return null;
    return ptr.ptr;
}

export fn roc_realloc(c_ptr: *anyopaque, new_size: usize, old_size: usize, alignment: u32) callconv(.C) ?*anyopaque {
    _ = alignment;
    _ = old_size;
    // For simplicity in the primer, we'll just reallocate with c_allocator
    // but correctly we should know the old_size.
    // std.heap.c_allocator.realloc is safer but needs a slice.
    return null; // Should not be needed for this simple app
}

export fn roc_dealloc(c_ptr: *anyopaque, alignment: u32) callconv(.C) void {
    _ = alignment;
    _ = c_ptr;
}

export fn roc_panic(msg: *anyopaque, tag_id: u32) callconv(.C) void {
    _ = msg;
    _ = tag_id;
    std.process.exit(1);
}

export fn roc_dbg(loc: *anyopaque, msg: *anyopaque, src: *anyopaque) callconv(.C) void {
    _ = loc; _ = msg; _ = src;
}

export fn roc_memset(dst: [*]u8, value: i32, size: usize) callconv(.C) void {
    @memset(dst[0..size], @intCast(value));
}
