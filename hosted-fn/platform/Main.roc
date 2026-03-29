platform ""
    requires {} {
        main! : {} => I32
    }
    exposes [Add]
    packages {}
    provides { main_for_host!: "main" }

import Add

main_for_host! : {} => I32
main_for_host! = |{}|
    main! {}
