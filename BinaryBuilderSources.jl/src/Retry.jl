using Downloads

"""
    network_retry_delays

The delays (in seconds) to wait between attempts of a network operation run through
`with_network_retries()`.  An operation is attempted `length(network_retry_delays[]) + 1`
times in total.  Tests replace this to retry without waiting.
"""
const network_retry_delays = Ref{Vector{Float64}}([1.0, 4.0, 16.0])

# libcurl error codes that mean the request itself is malformed, and that no
# number of retries will fix (unsupported protocol, malformed URL).
const permanent_curl_codes = (1, 3)

"""
    is_transient_network_error(e)

Return `true` if `e` is the kind of network failure that may go away if the operation is
simply attempted again: connection failures, timeouts and dropped connections, as well
as HTTP responses that mean "try again later" (408, 429 and 5xx).  Other HTTP errors
(e.g. 404) and non-network errors (e.g. hash mismatches) are not transient.
"""
is_transient_network_error(::Any) = false
is_transient_network_error(::Base.IOError) = true
is_transient_network_error(::Base.EOFError) = true
function is_transient_network_error(e::Downloads.RequestError)
    # A nonzero `code` is a libcurl error, i.e. the transfer itself failed.
    if e.code != 0
        return e.code ∉ permanent_curl_codes
    end
    # Otherwise the server answered with an HTTP error status.
    status = e.response.status
    return status == 408 || status == 429 || 500 <= status <= 599
end

"""
    with_network_retries(f, what; is_transient = is_transient_network_error,
                         delays = network_retry_delays[])

Call `f()`, and if it throws an error for which `is_transient(err)` is true, wait for the
next entry of `delays` seconds and call it again, until it succeeds or the delays are
exhausted, at which point the last error is rethrown.  Errors that are not transient are
rethrown immediately.  `what` describes the operation in the warning logged for each
failed attempt.
"""
function with_network_retries(f::Function, what::AbstractString;
                              is_transient::Function = is_transient_network_error,
                              delays::Vector{<:Real} = network_retry_delays[])
    num_attempts = length(delays) + 1
    for attempt in 1:num_attempts
        try
            return f()
        catch e
            if attempt == num_attempts || !is_transient(e)
                rethrow()
            end
            delay = delays[attempt]
            @warn("$(what) failed (attempt $(attempt)/$(num_attempts)), retrying in $(delay)s",
                  exception=e)
            sleep(delay)
        end
    end
end

"""
    to_urls(url)

Normalize the `url` argument of a source constructor, either a single URL or
a vector of URLs to try in order, to a non-empty `Vector{String}`.
"""
to_urls(url::AbstractString) = [string(url)]
function to_urls(urls::AbstractVector)
    if isempty(urls)
        throw(ArgumentError("At least one URL must be given"))
    end
    return String[string(u) for u in urls]
end

"""
    MirrorsFailedError(errors)

Thrown when downloading a source from every one of its URLs failed; `errors` pairs
each URL with the error its last attempt failed with.
"""
struct MirrorsFailedError <: Exception
    errors::Vector{Pair{String,Any}}
end

function Base.showerror(io::IO, e::MirrorsFailedError)
    print(io, "MirrorsFailedError: all $(length(e.errors)) URLs failed:")
    for (url, err) in e.errors
        print(io, "\n  ", url, ": ")
        showerror(io, err)
    end
end
