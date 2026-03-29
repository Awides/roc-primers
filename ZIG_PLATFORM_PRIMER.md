# Roc Zig Platform Primer (Zig Compiler)

This guide covers building a platform for Roc's new Zig-based compiler.

## 1. Platform Definition (`Main.roc`)

The Zig compiler uses `requires` and `provides` to link the host and app.

```roc
platform ""
    requires {} { 
        main! : List(Str) => Try({}, [Exit(I8), ..]) 
    }
    exposes [Stdout]
    packages {}
    provides { main_for_host!: "main" }

import Stdout

main_for_host! : List(Str) => I8
main_for_host! = |args|
    match main!(args) {
        Ok({}) => 0
        Err(Exit(code)) => code
        Err(other) => 1
    }
```

## 2. Zig Host Entry Point (`host.zig`)

The host must export certain functions for the Roc runtime.

### Memory Allocation
The Roc runtime expects `roc_alloc`, `roc_realloc`, and `roc_dealloc`.

```zig
export fn roc_alloc(size: usize, alignment: u32) callconv(.C) ?*anyopaque {
    return std.heap.c_allocator.rawAlloc(size, @intCast(alignment), @returnAddress()) orelse null;
}
```

### Runtime Hooks
```zig
export fn roc_panic(msg: *RocStr, tag_id: u32) callconv(.C) void {
    // tag_id: 0 for stdlib, 1 for app
    std.debug.print("Roc panicked: {s}\n", .{msg.asSlice()});
    std.process.exit(1);
}

export fn roc_dbg(loc: *RocStr, msg: *RocStr, src: *RocStr) callconv(.C) void {
    std.debug.print("[{s}] {s} = {s}\n", .{ loc.asSlice(), src.asSlice(), msg.asSlice() });
}
```

## 3. The Surgical Linker

The new compiler uses a **Surgical Linker** for near-instant compilation.
- **`host.o`**: Pre-compiled host object file.
- **`metadata.rm`**: Metadata for the surgical linker.
- **`linux-x64.rh`**: The surgical host file.

### Pre-processing
`roc preprocess host.o metadata.rm linux-x64.rh`

## 4. Builtins and ABI

The Zig compiler implementation lives in `src/builtins/`.
It provides its own `roc_builtins.o` which must be linked.

### Interfacing Types
Roc types have a stable C layout defined in `src/glue/`.

```zig
pub const RocStr = extern struct {
    bytes: ?[*]u8,
    len: usize,
    capacity: usize,

    pub fn asSlice(self: RocStr) []const u8 {
        if (self.bytes == null) return &[_]u8{};
        return self.bytes.?[0..self.len];
    }
};
```

## 5. Directory Structure
```text
my-platform/
  Main.roc
  host.zig
  targets/
    linux-x64.rh
    linux-x64.rm
```
In `Main.roc`, targets are defined as:
```roc
    targets: {
        files: "targets/",
        exe: {
            linux-x64: ["libhost.a", app]
        }
    }
```
*(Note: Legacy platforms use `.a`, modern ones use `.rh` for the surgical linker.)*
