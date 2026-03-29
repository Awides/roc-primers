# Roc Language Primer (Zig Compiler)

Roc's new Zig-based compiler (in `src/`) uses modern syntax and a performance-oriented effect system.

## 1. Modules and Apps

An **App** defines a program and provides its entry point to a platform.

```roc
app "hello-world"
    packages { pf: "platform/Main.roc" }
    provides [main!] to pf

main! : List(Str) => Try({}, [Exit(I8), ..])
main! = |args|
    Stdout.line!("Hello, Roc!")
    Ok({})
```

## 2. Modern Syntax (Zig Compiler)

### Functions and Anonymous Functions
- Definitions: `add = |a, b| a + b`
- Pipelines: `[1, 2, 3] |> List.map(|n| n * 2)`
- Backpassing: `n <- List.map([1, 2, 3])`

### Control Flow: `match`
The new compiler uses `match` for pattern matching (replacing `when`).

```roc
match status {
    Loading => "Loading..."
    Ready(msg) => "Ready: ${msg}"
    Err(code) => "Error: ${Num.toStr(code)}"
}
```

### Effects: `!`
Effectful functions are marked with `!`. They can be "called" directly in an effectful context.

```roc
main! = |args|
    name <- Stdin.line!("Name?")
    Stdout.line!("Hello, ${name}!")
    Ok({})
```

### Error Handling: `Try`
`Try(T, E)` is the new `Result(T, E)`.
- `Ok(value)`
- `Err(error)`

## 3. Data Structures

### Records
- `{ name: "Roc", version: 1 }`
- Access: `record.name`
- Update: `{ record & version: 2 }`

### Tagged Unions (Variants)
- `Status : [Loading, Ready(Str), Err(U8)]`

### Lists and Dicts
- `List(T)`: `[1, 2, 3]`
- `Dict(K, V)`: Key-value map.

## 4. Opaque Types
- `MyType := Str`
- `@MyType("secret")`
- Unwrapping: `|@MyType(inner)| inner`
