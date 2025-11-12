using Documenter
using BinaryBuilder2

DocMeta.setdocmeta!(
    BinaryBuilder2,
    :DocTestSetup,
    :(using BinaryBuilder2);
    recursive=true,
)

makedocs(
    sitename = "BinaryBuilder2",
    format = Documenter.HTML(),
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

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
