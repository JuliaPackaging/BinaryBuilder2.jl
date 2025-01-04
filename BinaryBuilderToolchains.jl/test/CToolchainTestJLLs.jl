using BinaryBuilderSources, LazyJLLWrappers, Pkg, BinaryBuilderPlatformExtensions

cxx_csl_libs = [
    JLLSource(
        "libstdcxx_jll",
        BBHostPlatform();
        uuid=Base.UUID("3ba1ab17-c18f-5d2d-9d5a-db37f286de95"),
        repo=Pkg.Types.GitRepo(
            rev="bb2/GCC",
            source="https://github.com/staticfloat/libstdcxx_jll.jl",
        ),
        version=v"9.4.0",
    ),
    JLLSource(
        "LLVMLibcxx_jll",
        BBHostPlatform();
        uuid=Base.UUID("899a7460-a157-599b-96c7-ccb58ef9beb5"),
        repo=Pkg.Types.GitRepo(
            rev="bb2/GCC",
            source="https://github.com/staticfloat/LLVMLibcxx_jll.jl",
        ),
        version=v"17.0.1",
    ),
    JLLSource(
        "LLVMLibunwind_jll",
        BBHostPlatform();
        uuid=Base.UUID("871c935c-5660-55ad-bb68-d1283357316b"),
        repo=Pkg.Types.GitRepo(
            rev="bb2/GCC",
            source="https://github.com/staticfloat/LLVMLibunwind_jll.jl",
        ),
        version=v"17.0.1",
    ),
]
prepare(cxx_csl_libs)

function with_cxx_csls(f::Function; env=copy(ENV))
    mktempdir() do prefix
        deploy(cxx_csl_libs, prefix)
        libpath = string(
            joinpath(prefix, "lib"),
            LazyJLLWrappers.pathsep,
            joinpath(prefix, triplet(BBHostPlatform()), "lib"),
            LazyJLLWrappers.pathsep,
            joinpath(prefix, triplet(BBHostPlatform()), "lib64"),
        )
        env = LazyJLLWrappers.adjust_ENV!(env, "", libpath, false, true)
        f(env)
    end
end
