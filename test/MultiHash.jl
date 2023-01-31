using Test, BB2, SHA

@testset "MultiHash" begin
    using BB2: hash_length, hash_prefix, MULTIHASH_TYPES

    HASH_TEST_HASHES = Dict(
        SHA1Hash => sha1("BB2"),
        SHA256Hash => sha256("BB2"),
    )
    HASH_TEST_SETS = Tuple[]
    for H in MULTIHASH_TYPES
        h_str = bytes2hex(HASH_TEST_HASHES[H])
        append!(HASH_TEST_SETS, [
            (H, HASH_TEST_HASHES[H], hash_length(H), hash_prefix(H), h_str),
            (H, HASH_TEST_HASHES[H], hash_length(H), hash_prefix(H), uppercase(h_str)),
            (H, HASH_TEST_HASHES[H], hash_length(H), hash_prefix(H), "$(hash_prefix(H)):$(h_str)"),
            (H, HASH_TEST_HASHES[H], hash_length(H), hash_prefix(H), hex2bytes(h_str)),
            (H, HASH_TEST_HASHES[H], hash_length(H), hash_prefix(H), tuple(hex2bytes(h_str)...)),
        ])
    end

    # Test that fully-specified parsing works correctly:
    for (H, h_bytes, len, prefix, h_str) in HASH_TEST_SETS
        h = MultiHash(h_str)
        @test isa(h, H)
        @test hash_length(h) == len
        @test hash_prefix(h) == prefix
        @test startswith(string(h), prefix)
        @test h == h_bytes
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
