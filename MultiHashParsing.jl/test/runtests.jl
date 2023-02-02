using Test, MultiHashParsing, SHA

@testset "MultiHash" begin
    using MultiHashParsing: hash_length, hash_prefix, MULTIHASH_TYPES, hash_like, verify

    HASH_TEST_HASHES = Dict(
        SHA1Hash => sha1("MultiHashParsing"),
        SHA256Hash => sha256("MultiHashParsing"),
    )
    HASH_TEST_SETS = Tuple[]
    for H in MULTIHASH_TYPES
        push!(HASH_TEST_SETS,
            (H,
            HASH_TEST_HASHES[H],
            hash_length(H),
            hash_prefix(H),
            bytes2hex(HASH_TEST_HASHES[H])),
        )
    end

    # Test that fully-specified parsing works correctly:
    for (H, h_bytes, len, prefix, h_str) in HASH_TEST_SETS
        h = MultiHash(h_str)
        @test isa(h, H)
        @test hash_length(h) == len
        @test hash_prefix(h) == prefix
        @test startswith(string(h), prefix)
        @test h == h_bytes
        @test bytes2hex(h) == lowercase(h_str)
        @test hash_like(h, "MultiHashParsing") == h
        @test verify(h, "MultiHashParsing")

        @test MultiHash(h) == h
        @test MultiHash(uppercase(h_str)) == h
        @test MultiHash(tuple(hex2bytes(h_str)...)) == h
        @test MultiHash("$(prefix):$(h_str)") == h
        @test MultiHash("$(prefix):$(uppercase(h_str))") == h
        @test MultiHash(hex2bytes(h_str)) == h
    end

    # Test that attempting to feed in bad hashes doesn't work:
    @test_throws ArgumentError MultiHash("0")
    @test_throws ArgumentError MultiHash("00")
    @test_throws ArgumentError MultiHash("x")
    for H in MULTIHASH_TYPES
        @test_throws ArgumentError MultiHash(string(hash_prefix(H), ":", "00"))
        @test_throws ArgumentError MultiHash(string(hash_prefix(H), ":", "x"^hash_length(H)))
    end
end
