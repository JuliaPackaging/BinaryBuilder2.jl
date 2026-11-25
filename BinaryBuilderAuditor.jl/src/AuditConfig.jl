export AuditConfig

"""
    AuditConfig(; kwargs...)

Selects which of `audit!()`'s passes run.  Each field is named after a pass
(without its trailing `!`) and defaults to `true`; set one to `false` to turn
that pass off, e.g. `AuditConfig(; rpaths_consistent = false)`.  A disabled pass
records a single `:skipped` entry in the audit result instead of running.

Passes whose output the rest of the build relies upon cannot be disabled:
`resolve_dynamic_links!` and `resolve_static_libraries!` (which describe the
library products), `record_runtime_requirements!` (which feeds packaging), and
`ensure_codesigned!` (which must follow any pass that modifies a binary).
"""
Base.@kwdef struct AuditConfig
    absolute_to_relative_symlinks::Bool = true
    dangling_symlinks::Bool = true
    relocate_pkgconfig_files::Bool = true
    remove_libtool_archives::Bool = true
    ensure_sonames::Bool = true
    relink_absolute_dependencies::Bool = true
    rpaths_consistent::Bool = true
    licenses_present::Bool = true
    check_runtime_requirements::Bool = true
end

"""
    disabled_passes(config::AuditConfig)

Names of the passes that `config` turns off, in pass order.
"""
disabled_passes(config::AuditConfig) = Symbol[f for f in fieldnames(AuditConfig) if !getfield(config, f)]

function Base.show(io::IO, config::AuditConfig)
    disabled = disabled_passes(config)
    print(io, "AuditConfig(", join(("$(f) = false" for f in disabled), ", "), ")")
end

# Run `f()` if the pass `name` is enabled; otherwise record that it was skipped.
function run_pass(f::Function, result::AuditResult, config::AuditConfig, name::Symbol, pass_name::String)
    if getfield(config, name)
        f()
    else
        push_result!(result.pass_results, pass_name, :skipped, result.scan.prefix, "disabled by AuditConfig")
    end
    return nothing
end
