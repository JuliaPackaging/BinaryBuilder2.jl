using Test, BinaryBuilderToolchains
using BinaryBuilderToolchains: compiler_wrapper, jobserver_jll

# A fake "compiler" that records how many copies of itself run at once.
const counting_job = raw"""
#!/bin/bash
state="$1"; duration="$2"; status="${3:-0}"
exec 9>"${state}/count.lock"
flock 9
n=$(( $(cat "${state}/count" 2>/dev/null || echo 0) + 1 ))
echo "${n}" > "${state}/count"
echo "${n}" >> "${state}/samples"
flock -u 9
touch "${state}/running.$$"
sleep "${duration}"
flock 9
echo $(( $(cat "${state}/count") - 1 )) > "${state}/count"
flock -u 9
exit "${status}"
"""

# A tool that runs another jobserver wrapper, like `gcc` running `as`.
const nesting_job = raw"""
#!/bin/bash
exec "${INNER_WRAPPER}" "$@"
"""

struct JobserverEnv
    dir::String
    bin::String
    daemon_dir::String
    state::String
    wrapper::String
    nested_wrapper::String
end

function JobserverEnv(dir::String)
    tools = joinpath(dir, "bb_jobserver")
    jll = jobserver_jll(HostPlatform())
    prepare([jll])
    deploy([jll], tools)
    bin = joinpath(tools, "bin", "bb_jobserver")
    state = mkpath(joinpath(dir, "state"))
    job = joinpath(dir, "counting_job")
    write(job, counting_job)
    chmod(job, 0o755)
    wrapper = joinpath(dir, "job-wrapper")
    compiler_wrapper(wrapper, job; jobserver=true)

    nesting = joinpath(dir, "nesting_job")
    write(nesting, nesting_job)
    chmod(nesting, 0o755)
    nested_wrapper = joinpath(dir, "nesting-wrapper")
    compiler_wrapper(nested_wrapper, nesting; jobserver=true)
    return JobserverEnv(dir, bin, joinpath(dir, "daemon"), state, wrapper, nested_wrapper)
end

# A `bb_jobserver session`, as BinaryBuilder2 runs one for each build
function start_session(js::JobserverEnv, num_slots::Int; daemon_dir = js.daemon_dir)
    cmd = addenv(`$(js.bin) session $(daemon_dir) $(num_slots)`, "BB_JOBSERVER_IDLE_TIMEOUT_MS" => "300")
    p = open(pipeline(cmd; stderr), "r+")
    @test readline(p) == "ready"
    return p
end

function stop_session(p)
    close(p.in)
    wait(p)
    @test success(p)
end

daemon_pid(daemon_dir) = parse(Int, readchomp(joinpath(daemon_dir, "daemon.lock")))
process_alive(pid) = isdir("/proc/$(pid)") && !occursin("State:\tZ", read("/proc/$(pid)/status", String))

# The environment of one build's sandbox
build_env(js, group = "build"; daemon_dir = js.daemon_dir) = Dict(
    "BB_JOBSERVER_SOCKET" => joinpath(daemon_dir, "socket"),
    "BB_JOBSERVER_BIN" => js.bin,
    "BB_JOBSERVER_GROUP" => group,
    "INNER_WRAPPER" => js.wrapper,
)

job_cmd(js, env, duration; status = 0, wrapper = js.wrapper) =
    addenv(`$(wrapper) $(js.state) $(duration) $(status)`, env)
job(args...; kwargs...) = pipeline(job_cmd(args...; kwargs...); stdin=devnull)

max_concurrency(js) = maximum(parse.(Int, readlines(joinpath(js.state, "samples"))))
# Only call this while no job runs, or the running count goes wrong
function reset_samples(js)
    rm(joinpath(js.state, "samples"); force=true)
    write(joinpath(js.state, "count"), "0\n")
end
running_markers(js) = filter(startswith("running."), readdir(js.state))
clear_markers(js) = foreach(f -> rm(joinpath(js.state, f)), running_markers(js))

function wait_until(f; timeout = 10.0)
    t0 = time()
    while !f()
        time() - t0 > timeout && return false
        sleep(0.02)
    end
    return true
end

function start_hogs(js, env, n)
    clear_markers(js)
    hogs = [run(job(js, env, 5); wait=false) for _ in 1:n]
    @test wait_until(() -> length(running_markers(js)) == n)
    return hogs
end

function stop_hogs(js, hogs)
    foreach(h -> process_running(h) && kill(h, Base.SIGKILL), hogs)
    foreach(wait, hogs)
    # Only the hogs' tools: other tests' jobs may get their slots meanwhile
    run(ignorestatus(`pkill -KILL -f "counting_job $(js.state) 5"`))
    @test wait_until(() -> !success(`pgrep -f "counting_job $(js.state) 5"`))
end

@testset "Jobserver" begin
    if !Sys.islinux() || Sys.which("flock") === nothing
        @warn("Skipping jobserver tests: they need Linux and `flock`")
        return
    end

    mktempdir() do dir
        js = JobserverEnv(dir)

        @testset "without a jobserver, wrappers run immediately" begin
            reset_samples(js)
            procs = [run(`$(js.wrapper) $(js.state) 0.5`; wait=false) for _ in 1:4]
            @test all(success, procs)
            @test max_concurrency(js) == 4
        end

        @testset "wrappers run immediately when the daemon can't be reached" begin
            reset_samples(js)
            env = build_env(js; daemon_dir = joinpath(dir, "nonexistent"))
            t0 = time()
            procs = [run(job(js, env, 0.5); wait=false) for _ in 1:4]
            @test all(success, procs)
            @test max_concurrency(js) == 4
            @test time() - t0 < 2.0
        end

        session = start_session(js, 3)
        env = build_env(js)
        try
            @testset "sessions share one daemon" begin
                pid = daemon_pid(js.daemon_dir)
                @test process_alive(pid)
                other = start_session(js, 3)
                @test daemon_pid(js.daemon_dir) == pid
                stop_session(other)
            end

            @testset "concurrency never exceeds the slot count" begin
                reset_samples(js)
                t0 = time()
                procs = [run(job(js, env, 0.3); wait=false) for _ in 1:12]
                @test all(success, procs)
                @test max_concurrency(js) == 3
                # 12 jobs on 3 slots is 4 rounds of 0.3s
                @test 1.1 < time() - t0 < 4.0
            end

            @testset "an uncontended slot is granted quickly" begin
                run(job(js, env, 0.0))
                t = @elapsed for _ in 1:20
                    run(job(js, env, 0.0))
                end
                @test t < 1.5
            end

            @testset "exit status is preserved and the slot is returned" begin
                p = run(pipeline(ignorestatus(job_cmd(js, env, 0.0; status = 3)); stdin=devnull))
                @test p.exitcode == 3
                reset_samples(js)
                @test all(success, [run(job(js, env, 1.0); wait=false) for _ in 1:3])
                @test max_concurrency(js) == 3
            end

            @testset "nested wrappers reuse their parent's slot" begin
                reset_samples(js)
                procs = [run(job(js, env, 0.3; wrapper = js.nested_wrapper); wait=false) for _ in 1:6]
                @test all(success, procs)
                @test max_concurrency(js) == 3
            end

            @testset "a killed tool's slot is returned at once" begin
                hogs = start_hogs(js, env, 3)
                # `running.<pid>` names the tool process itself, which `bb_jobserver run`
                # exec'ed into; its `sleep` child keeps running after the kill.
                tool_pid = parse(Int, split(first(running_markers(js)), ".")[2])
                run(`kill -KILL $(tool_pid)`)
                t0 = time()
                @test success(run(job(js, env, 0.0)))
                @test time() - t0 < 0.3
                stop_hogs(js, hogs)
            end

            @testset "killing a waiting wrapper withdraws its request" begin
                hogs = start_hogs(js, env, 3)
                waiter = run(job(js, env, 0.0); wait=false)
                sleep(0.3)
                @test process_running(waiter)
                kill(waiter, Base.SIGTERM)
                wait(waiter)
                @test waiter.termsignal == Base.SIGTERM
                clear_markers(js)
                stop_hogs(js, hogs)
                # The tool must never start, not even once the slots are free
                sleep(0.5)
                @test isempty(running_markers(js))
            end

            @testset "a pipeline consumer runs without a slot when its producer is stuck" begin
                hogs = start_hogs(js, env, 3)
                # The producer keeps the pipe open after writing, like one blocked on a
                # full pipe while holding the slot the consumer waits for
                producer = `bash -c "echo hello; sleep 3"`
                t0 = time()
                @test success(pipeline(producer, job_cmd(js, env, 0.0)))
                # The consumer ran after 0.5s; the pipeline then waits for the producer
                @test 2.9 < time() - t0 < 4.0
                @test isfile(joinpath(js.state, "count")) && length(running_markers(js)) == 4
                stop_hogs(js, hogs)
            end

            @testset "a pipeline consumer whose producer is done waits for its slot" begin
                hogs = start_hogs(js, env, 3)
                consumer = run(pipeline(`echo hello`, job_cmd(js, env, 0.0)); wait=false)
                sleep(1.0)
                @test process_running(consumer)
                @test length(running_markers(js)) == 3
                stop_hogs(js, hogs)
                @test success(consumer)
            end

            @testset "a stdin pipe at EOF (as `make -j` gives its jobs) doesn't count as a pipeline" begin
                hogs = start_hogs(js, env, 3)
                eof_stdin_job = `bash -c "exec < <(:); sleep 0.1; exec $(js.wrapper) $(js.state) 0.0"`
                waiter = run(addenv(eof_stdin_job, env); wait=false)
                sleep(1.5)
                @test process_running(waiter)
                stop_hogs(js, hogs)
                @test success(waiter)
            end

            if Sys.which("make") !== nothing
                @testset "make -j16 runs at most as many jobs as there are slots" begin
                    reset_samples(js)
                    makefile = joinpath(js.dir, "Makefile")
                    targets = ["t$(i)" for i in 1:9]
                    open(makefile; write=true) do io
                        println(io, "all: ", join(targets, " "))
                        for t in targets
                            println(io, t, ":\n\t@$(js.wrapper) $(js.state) 0.3")
                        end
                    end
                    t0 = time()
                    @test success(addenv(`make -s -j16 -f $(makefile)`, env))
                    @test max_concurrency(js) == 3
                    @test time() - t0 > 0.85
                end
            end

            @testset "the largest pool asked for by a session applies" begin
                bigger = start_session(js, 5)
                reset_samples(js)
                @test all(success, [run(job(js, env, 0.3); wait=false) for _ in 1:10])
                @test max_concurrency(js) == 5
                stop_session(bigger)
                reset_samples(js)
                @test all(success, [run(job(js, env, 0.3); wait=false) for _ in 1:10])
                @test max_concurrency(js) == 3
            end

            @testset "two builds share the pool fairly" begin
                reset_samples(js)
                t0 = time()
                p1 = [run(job(js, build_env(js, "build1"), 0.2); wait=false) for _ in 1:16]
                sleep(0.1)
                p2 = [run(job(js, build_env(js, "build2"), 0.2); wait=false) for _ in 1:16]
                finish = Float64[]
                @sync for ps in (p1, p2)
                    @async begin
                        foreach(wait, ps)
                        push!(finish, time() - t0)
                    end
                end
                @test all(success, vcat(p1, p2))
                @test max_concurrency(js) == 3
                # 32 jobs of 0.2s on 3 slots take about 2.2s; build2 started later, but
                # takes turns with build1 instead of waiting for it to finish.
                @test abs(finish[1] - finish[2]) < 0.6
            end

            @testset "a session restarts a daemon that died" begin
                old = daemon_pid(js.daemon_dir)
                run(`kill -KILL $(old)`)
                @test wait_until(() -> isfile(joinpath(js.daemon_dir, "daemon.lock")) &&
                                       daemon_pid(js.daemon_dir) != old && process_alive(daemon_pid(js.daemon_dir)))
                reset_samples(js)
                @test all(success, [run(job(js, env, 0.2); wait=false) for _ in 1:6])
                @test max_concurrency(js) == 3
            end
        finally
            stop_session(session)
        end

        @testset "the daemon exits once no session is left" begin
            pid = daemon_pid(js.daemon_dir)
            @test wait_until(() -> !process_alive(pid); timeout = 3.0)
            @test !ispath(joinpath(js.daemon_dir, "socket"))
            t0 = time()
            @test success(run(job(js, env, 0.0)))
            @test time() - t0 < 2.0
        end

        @testset "concurrent sessions start a single daemon" begin
            daemon_dir = joinpath(dir, "race")
            sessions = Vector{Any}(undef, 8)
            @sync for i in 1:8
                @async sessions[i] = start_session(js, 2; daemon_dir)
            end
            pid = daemon_pid(daemon_dir)
            @test process_alive(pid)
            # Every session process plus exactly one daemon
            ours = filter(readdir("/proc")) do p
                all(isdigit, p) || return false
                cmdline = try read("/proc/$(p)/cmdline", String) catch; "" end
                return occursin("session\0$(daemon_dir)\0", cmdline)
            end
            @test length(ours) == 9
            foreach(stop_session, sessions)
        end

        @testset "socket paths longer than sun_path work" begin
            daemon_dir = joinpath(dir, "x"^60, "y"^60)
            mkpath(dirname(daemon_dir))
            s = start_session(js, 2; daemon_dir)
            reset_samples(js)
            @test all(success, [run(job(js, build_env(js; daemon_dir), 0.3); wait=false) for _ in 1:4])
            @test max_concurrency(js) == 2
            stop_session(s)
        end

        # A daemon in its own pid namespace can't see its clients' pids, so it can't
        # watch them; `run` then keeps the connection open in a helper process instead.
        if success(pipeline(`unshare --user --pid --fork --map-root-user true`; stderr=devnull))
            @testset "slots are held through the connection when the daemon can't see pids" begin
                daemon_dir = joinpath(dir, "pidns")
                cmd = addenv(`unshare --user --pid --fork --map-root-user $(js.bin) session $(daemon_dir) 2`,
                             "BB_JOBSERVER_IDLE_TIMEOUT_MS" => "300")
                s = open(pipeline(cmd; stderr), "r+")
                @test readline(s) == "ready"
                penv = build_env(js; daemon_dir)
                reset_samples(js)
                @test all(success, [run(job(js, penv, 0.3); wait=false) for _ in 1:6])
                @test max_concurrency(js) == 2
                # A killed tool's helper notices at once
                hogs = start_hogs(js, penv, 2)
                tool_pid = parse(Int, split(first(running_markers(js)), ".")[2])
                run(`kill -KILL $(tool_pid)`)
                t0 = time()
                @test success(run(job(js, penv, 0.0)))
                @test time() - t0 < 0.3
                stop_hogs(js, hogs)
                stop_session(s)
            end
        end

        @testset "malformed command lines are rejected" begin
            @test !success(pipeline(`$(js.bin) session $(js.daemon_dir) zero`; stderr=devnull))
            @test !success(pipeline(`$(js.bin) run`; stderr=devnull))
            @test !success(pipeline(`$(js.bin) frobnicate`; stderr=devnull))
        end
    end
end
