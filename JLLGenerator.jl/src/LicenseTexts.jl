const license_texts = Dict{String,String}()

# NOTE: Adding a new license 
for license_name in readdir(joinpath(@__DIR__, "license_raw_texts"))
    license_texts[license_name] = String(read(joinpath(@__DIR__, "license_raw_texts", license_name)))
end

function get_license_text(license_name::String)
    if !haskey(license_texts, license_name)
        throw(ArgumentError("We do not have $(license_name) as a vendored license blob yet!"))
    end
    return license_texts[license_name]
end
