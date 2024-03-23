jll = JLLInfo(;
    name = "Vulkan_Headers",
    version = v"1.3.243+1",
    artifacts = [
        JLLArtifactInfo(;
            src_version = v"1.3.243+1",
            deps = [
            ],
            sources = [],
            platform = AnyPlatform(),
            name = "Vulkan_Headers",
            treehash = "8bfcdb8832078af6cc9667780f1d15e9897c18bf",
            download_sources = [
                JLLArtifactSource(
                    "https://github.com/JuliaBinaryWrappers/Vulkan_Headers_jll.jl/releases/download/Vulkan_Headers-v1.3.243+1/Vulkan_Headers.v1.3.243.any.tar.gz",
                    "f7953a556cae59410875a77b0a998f7190e3aa04c64814d609679d6ccaa16ca9",
                ),
            ],
            products = [
                JLLFileProduct(
                    :vk_xml,
                    "share/vulkan/registry/vk.xml",
                ),
                JLLFileProduct(
                    :vulkan_hpp,
                    "include/vulkan/vulkan.hpp",
                ),
            ]
        ),

    ]
)

