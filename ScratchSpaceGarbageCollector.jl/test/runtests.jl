using Test, ScratchSpaceGarbageCollector, Dates

mktempdir() do test_depot
    @testset "MaxAgePolicy" begin
        arena = Arena(@pkg_uuid(), "test1", MaxAgePolicy(Second(5)); depot_path=test_depot)

        t₀ = Dates.now()
        old_space = get_scratch!(arena, "old"; curr_time=t₀ - Second(6))
        touch(joinpath(old_space, "old"))

        new_space = get_scratch!(arena, "new"; curr_time=t₀ - Second(4))
        touch(joinpath(new_space, "new"))

        # Identify garbage at a time point that should show `old` being garbage, but `new` not being garbage.
        garbage = Set{String}()
        ScratchSpaceGarbageCollector.identify_garbage(only(arena.policies), arena, garbage; curr_time=t₀)
        @test only(garbage) == "old"

        garbage = Set{String}()
        ScratchSpaceGarbageCollector.identify_garbage(only(arena.policies), arena, garbage; curr_time=t₀ + Second(2))
        @test sort(collect(garbage)) == ["new", "old"]

        # Test that `garbage_collect!()` works:
        garbage_collect!(arena; curr_time=t₀)
        @test !isdir(old_space)
        @test isdir(new_space)
    end


    @testset "MaxSizeLRUDropPolicy" begin
        arena = Arena(@pkg_uuid(), "test1", MaxSizeLRUDropPolicy(10); depot_path=test_depot)

        t₀ = Dates.now()
        old_space = get_scratch!(arena, "old"; curr_time=t₀ - Second(6))
        open(joinpath(old_space, "old"); write=true) do io
            write(io, "7 bytes")
        end

        new_space = get_scratch!(arena, "new"; curr_time=t₀ - Second(4))
        open(joinpath(old_space, "new"); write=true) do io
            write(io, "7 bytes")
        end

        garbage = Set{String}()
        ScratchSpaceGarbageCollector.identify_garbage(only(arena.policies), arena, garbage; curr_time=t₀ + Second(2))
        @test sort(collect(garbage)) == ["old"]

        # Test that `garbage_collect!()` works:
        garbage_collect!(arena; curr_time=t₀)
        @test !isdir(old_space)
        @test isdir(new_space)
    end
end
