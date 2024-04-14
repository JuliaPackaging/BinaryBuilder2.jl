## This file meant to be used as a transitioning aid to transition old JLL's
## to new ones.  It does a quick-and-dirty parsing and scraping of an old JLL
## to generate the layout of a new JLL.  The user will still have to fill out
## pieces of information such as per-library dependencies, so this is not
## completely automatic, but it's much better than having to sift through
## a bunch of artifact URLs and hashes by hand.

using TOML, Artifacts, BinaryBuilderGitUtils, Scratch, BinaryBuilderPlatformExtensions

if length(ARGS) ∉ (1, 2)
    println("Usage: $(@__FILE__) <JLL repo> [treelike]")
    exit(1)
end

repo_path = joinpath(@get_scratch!("jll_clones"), basename(ARGS[1]))
clone!(ARGS[1], repo_path)

library_products = Dict()
executable_products = Dict()
file_products = Dict()
mktempdir() do dir
    checkout!(repo_path, dir, get(ARGS, 2, "main"))

    global artifacts_data = Artifacts.load_artifacts_toml(joinpath(dir, "Artifacts.toml"))
    
    #run(`cat $(first(readdir(joinpath(dir, "src", "wrappers"); join=true)))`)
    for f in readdir(joinpath(dir, "src", "wrappers"); join=true)
        if basename(f) == "any.jl"
            platform = AnyPlatform()
        else
            platform = parse(Platform, basename(f)[1:end-3])
        end

        library_products[platform] = []
        for match in eachmatch(r"@init_library_product\((.+?)\)"s, String(read(f)))
            lines = split(match.captures[1], "\n")
            name = strip(lines[2][1:end-1])
            path = rstrip(lstrip(strip(lines[3][1:end-1]), '"'), '"')
            flags = Symbol.(strip.(split(strip(lines[4][1:end-1]), "|")))
            push!(library_products[platform], (name, path, flags))
        end

        executable_products[platform] = []
        for match in eachmatch(r"@init_executable_product\((.+?)\)"s, String(read(f)))
            lines = split(match.captures[1], "\n")
            name = strip(lines[2][1:end-1])
            path = rstrip(lstrip(strip(lines[3][1:end-1]), '"'), '"')
            push!(executable_products[platform], (name, path))
        end

        file_products[platform] = []
        for match in eachmatch(r"@init_file_product\((.+?)\)"s, String(read(f)))
            lines = split(match.captures[1], "\n")
            name = strip(lines[2][1:end-1])
            path = rstrip(lstrip(strip(lines[3][1:end-1]), '"'), '"')
            push!(file_products[platform], (name, path))
        end
    end

    global project = TOML.parsefile(joinpath(dir, "Project.toml"))
    global deps = []
    for (name, uuid) in project["deps"]
        # Drop default dependencies `JLLWrappers`, `Artifacts` and `Libdl`, these are implicit.
        if name ∈ ("LazyJLLWrappers", "JLLWrappers", "Artifacts", "Libdl", "Pkg")
            continue
        end
        push!(deps, (
            name,
            uuid,
            get(project["compat"], name, "*"),
        ))
    end
end


function print_artifact_info(entry, platform, version, name)
    print("""
            JLLArtifactInfo(;
                src_version = v"$(version)",
                deps = [
    """)
    for (name, uuid, compat) in deps
        print("""
                        JLLPackageDependency(
                            "$(name)",
                            Base.UUID("$(uuid)"),
                            "$(compat)",
                        ),
        """)
    end

    print("""
                ],
                sources = [],
                platform = $(repr(platform)),
                name = "default",
                treehash = "$(entry["git-tree-sha1"])",
                download_sources = [
                    JLLArtifactSource(
                        "$(entry["download"][1]["url"])",
                        "$(entry["download"][1]["sha256"])",
                    ),
                ],
                products = [
    """)

    for (name, path, flags) in library_products[platform]
        print("""
                        JLLLibraryProduct(
                            :$(name),
                            "$(path)",
                            [<deps>],
                            $(repr(flags)),
                        ),
        """)
    end

    for (name, path) in executable_products[platform]
        print("""
                        JLLExecutableProduct(
                            :$(name),
                            "$(path)",
                        ),
        """)
    end

    for (name, path) in file_products[platform]
        print("""
                        JLLFileProduct(
                            :$(name),
                            "$(path)",
                        ),
        """)
    end

    println("""
                ]
            ),
    """)
end

function print_jll_info()
    name = only(keys(artifacts_data))
    version = project["version"]
    print("""
    jll = JLLInfo(;
        name = "$(name)",
        version = v"$(version)",
        artifacts = [
    """)

    if !isa(artifacts_data[name], Vector)
        print_artifact_info(artifacts_data[name], AnyPlatform(), version, name)
    else
        for entry in sort(artifacts_data[name]; by = entry -> triplet(Artifacts.unpack_platform(entry, name, "Artifacts.toml")))
            platform = Artifacts.unpack_platform(entry, name, "Artifacts.toml")
            print_artifact_info(entry, platform, version, name)
        end
    end
    println("""
        ]
    )
    """)
end

print_jll_info()
