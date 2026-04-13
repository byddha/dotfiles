return {
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--fallback-style=llvm",
        "--offset-encoding=utf-16",
    },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
    root_markers = {
        ".clangd",
        "compile_commands.json",
        "compile_flags.txt",
        "CMakeLists.txt",
        "Makefile",
        ".git",
    },
}
