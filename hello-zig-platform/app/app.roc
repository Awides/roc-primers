app "hello"
    packages { pf: "../platform/Main.roc" }
    provides [main!] to pf

main! = \{} -> {}
