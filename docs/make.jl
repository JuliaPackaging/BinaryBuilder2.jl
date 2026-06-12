using Documenter
using BinaryBuilder2

DocMeta.setdocmeta!(
    BinaryBuilder2,
    :DocTestSetup,
    :(using BinaryBuilder2);
    recursive=true,
)

makedocs(
    sitename = "BinaryBuilder2.jl",
    format = Documenter.HTML(
        repolink = "https://github.com/JuliaPackaging/BinaryBuilder2.jl",
    ),
    modules = [BinaryBuilder2],
    pages = [
        "Overview" => "index.md",
        "Usage" => [
            "Basic Usage" => "basic_usage.md",
        ],
        "Full API reference" => [
            "BinaryBuilder2" => "reference/BinaryBuilder2.md",
        ],
        "Advanced" => [
            "Nomenclature" => "advanced/Nomenclature.md",
            "VSCode debugging" => "advanced/launch_code_server.md",
            "BuildTargetSpec" => "advanced/BuildTargetSpec.md",
            "PlatformlessWrapper" => "advanced/PlatformlessWrapper.md",
        ],
    ],
    checkdocs = :warnonly,
)

deploydocs(
    repo = "github.com/JuliaPackaging/BinaryBuilder2.jl",
    devbranch = "main",
)
