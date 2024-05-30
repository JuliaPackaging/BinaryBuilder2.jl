jll = JLLInfo(;
    name = "MozillaCACerts",
    version = v"2023.1.10+0",
    builds = [
        JLLBuildInfo(;
            src_version = v"2023.1.10+0",
            deps = [
            ],
            sources = [],
            platform = AnyPlatform(),
            name = "default",
            artifact = JLLArtifactBinding(;
                treehash = "b9426fe58f49fb59d2ec2b359b8638e9d2f3c26f",
                download_sources = [
                    JLLArtifactSource(
                        "https://github.com/JuliaBinaryWrappers/MozillaCACerts_jll.jl/releases/download/MozillaCACerts-v2023.1.10+0/MozillaCACerts.v2023.1.10.any.tar.gz",
                        "5f79debc613ae682eece454562377cfd0eafc57b9a32c5c45e624d7cbb1bc1a7",
                    ),
                ],
            ),
            products = [
                JLLFileProduct(
                    :cacert,
                    "share/cacert.pem",
                ),
            ]
        ),

    ]
)

