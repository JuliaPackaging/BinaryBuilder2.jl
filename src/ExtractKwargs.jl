# I feel this should be in Base Julia
macro extract_kwargs!(kwargs, keys...)
    quote
        Dict(k => v for (k, v) in pairs($(esc(kwargs))) if k in $(esc(keys)))
    end
end
