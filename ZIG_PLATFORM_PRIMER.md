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

## 6. App-to-Host Calls (Hosted Functions)

To allow an app to call a function provided by the host (e.g., `Stdout.line!` or `Add.add`), the platform must define a **Type Module**.

### 1. Define the Type Module (`Add.roc`)
In the platform, create a module that defines an opaque type and the host functions as **annotation-only** declarations (no body).

```roc
# platform/Add.roc
Add := {} . {
    # No body = host-provided "hosted function"
    add : I32, I32 => I32
}
```

### 2. Expose and Import in Platform (`Main.roc`)
The platform must `expose` this module.

```roc
platform ""
    requires {} { main! : {} => {} }
    exposes [Add]
    packages {}
    provides { main_for_host!: "main" }

import Add
```

### 3. Call from the App (`app.roc`)
The app imports the module from the platform (`pf`) and calls the function using the `Type.function` syntax.

```roc
import pf.Add

main! = |{}|
    result = Add.add(1, 2)
    # ...
```

### 4. Implementation in Zig Host (`host.zig`)
The host provides these functions in an array passed via `RocOps`. **Crucial:** The array must be sorted **alphabetically** by the fully-qualified Roc name (e.g., `Add.add`, `Stdout.line!`).

```zig
// Zig Host implementation
fn hostedAdd(ops: *RocOps, ret: *i32, args: *const struct { a: i32, b: i32 }) callconv(.C) void {
    ret.* = args.a + args.b;
}

const hosted_fns = [_]HostedFn{
    hostedFn(&hostedAdd), // "Add.add"
};

// Pass to Roc in main
var ops = RocOps{
    // ... other fields
    .hosted_fns = .{
        .count = hosted_fns.len,
        .fns = @constCast(&hosted_fns),
    },
};
```
