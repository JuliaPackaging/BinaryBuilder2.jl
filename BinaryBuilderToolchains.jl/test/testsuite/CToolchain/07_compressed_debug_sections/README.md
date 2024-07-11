# Compressed Debug Sections test

This tests our ability to generate debug sections in ELF files via GCC's `-gz` option.
It uses `objcopy --dump-section` along with the `--decompress-debug-sections` option to test whether the debug sections are actually compressed or not, and whether they decompress to the same thing.
