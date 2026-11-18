using BinaryBuilder2, Test

if !isdefined(@__MODULE__, :TestingUtils)
    include(joinpath(pkgdir(BinaryBuilder2), "test", "TestingUtils.jl"))
end

# Compiles a few copies of a slow-to-compile file at once while counting the `cc1`
# processes in the sandbox, and fails if there were ever more than `$1` of them.
const jobserver_probe = raw"""
cat > /tmp/jobserver_probe.sh <<'EOF'
max_allowed="$1"
cd "$(mktemp -d)"
{ echo 'int f(int x) {'; for i in $(seq 1 1500); do echo "  x = x * $i + (x >> 3) ^ $i;"; done; echo '  return x; }'; } > slow.c
( while true; do
    n=0
    for c in /proc/[0-9]*/comm; do
        read -r x < "$c" 2>/dev/null && [[ "$x" == cc1 ]] && n=$((n+1))
    done
    echo "$n" >> samples
  done ) &
sampler=$!
make_jobs=()
for i in $(seq 1 6); do cc -O2 -c slow.c -o slow$i.o & make_jobs+=($!); done
wait "${make_jobs[@]}"
kill "${sampler}"
max_seen="$(sort -n samples | tail -1)"
echo "at most ${max_seen} cc1 processes ran at once (allowed: ${max_allowed})"
[[ "${max_seen}" -ge 1 ]] && [[ "${max_seen}" -le "${max_allowed}" ]]
EOF
"""

function jobserver_probe_build(script::String)
    meta = BuildMeta(; verbose=false, disabled_caches=["build"])
    config = BuildConfig(
        meta,
        "jobserver_probe",
        v"1.0.0",
        [],
        apply_spec_plan(spec_plan, native_linux, native_linux),
        string(jobserver_probe, script),
    )
    return build!(config)
end

@testset "Jobserver" begin
    withenv("BINARYBUILDER_JOBSERVER_SLOTS" => "2") do
        @test BinaryBuilder2.jobserver_slots() == 2
        result = jobserver_probe_build(raw"""
        [[ -S "${BB_JOBSERVER_SOCKET}" ]] && [[ -x "${BB_JOBSERVER_BIN}" ]] && [[ -n "${BB_JOBSERVER_GROUP}" ]]
        bash /tmp/jobserver_probe.sh 2
        """)
        @test result.status == :success
    end

    # With the jobserver disabled no session is started and nothing is throttled
    withenv("BINARYBUILDER_JOBSERVER_SLOTS" => "0") do
        result = jobserver_probe_build(raw"""
        [[ -z "${BB_JOBSERVER_SOCKET:-}" ]]
        bash /tmp/jobserver_probe.sh 6
        """)
        @test result.status == :success
    end
end
