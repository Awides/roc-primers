app "hello"
    packages { pf: "../platform/Main.roc" }
    provides [main!] to pf

import pf.Add

main! = |{}|
    Add.add(1, 2)
