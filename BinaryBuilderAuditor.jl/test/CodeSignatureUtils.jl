using ObjectFile, SHA
using ObjectFile.MachO: LC_CODE_SIGNATURE

"""
    codesignature_status(oh::MachOHandle)

Checks the code signature of a Mach-O object, as far as an ad-hoc signature can be
checked off-device: every `CodeDirectory` must cover the whole object up to the
signature, and the hash of each page must match its code slot.  Returns `:unsigned`,
`:invalid`, or `:adhoc` for a valid ad-hoc signature (one without a CMS blob;
`ldid` does not set the `CS_ADHOC` flag).
"""
function codesignature_status(oh::MachOHandle)
    lcs = MachOLoadCmds(oh)
    sig_idx = findfirst(idx -> header(lcs[idx]).cmd == LC_CODE_SIGNATURE, keys(lcs))
    if sig_idx === nothing
        return :unsigned
    end

    # `LC_CODE_SIGNATURE` is a `linkedit_data_command`: the offset and size of the signature
    seek(lcs[sig_idx])
    sig_off, sig_size = Int(ObjectFile.unpack(oh, UInt32)), Int(ObjectFile.unpack(oh, UInt32))
    seekstart(oh)
    data = read(ObjectFile.iostream(oh), sig_off + sig_size)

    # ObjectFile does not parse code signatures.  The signature is a big-endian
    # `SuperBlob` of blobs; check each `CodeDirectory` in it.
    be32(off) = ntoh(reinterpret(UInt32, data[off+1:off+4])[1])
    if be32(sig_off) != 0xfade0cc0
        return :invalid
    end
    num_cds = 0
    for idx in 0:be32(sig_off + 8)-1
        cd = sig_off + Int(be32(sig_off + 12 + 8*idx + 4))
        # A CMS signature blob makes this a non-ad-hoc signature
        if be32(cd) == 0xfade0b01 && be32(cd + 4) > 8
            return :invalid
        end
        if be32(cd) != 0xfade0c02
            continue
        end
        num_cds += 1
        hash_off, num_slots, code_limit = be32(cd + 16), be32(cd + 28), be32(cd + 32)
        hash_size, hash_type, page_size = Int(data[cd + 37]), data[cd + 38], 1 << data[cd + 40]
        hash_func = Dict(0x01 => sha1, 0x02 => sha256)[hash_type]
        if code_limit != sig_off
            return :invalid
        end
        for slot in 0:num_slots-1
            page = (slot*page_size + 1):min((slot + 1)*page_size, code_limit)
            slot_hash = data[(cd + hash_off + slot*hash_size + 1):(cd + hash_off + (slot + 1)*hash_size)]
            if hash_func(view(data, page)) != slot_hash
                return :invalid
            end
        end
    end
    return num_cds > 0 ? :adhoc : :invalid
end

"""
    codesignature_status(path::AbstractString)

Checks the code signature of every Mach-O object in the file at `path` (one per
architecture in a universal binary), returning `:adhoc` only if they are all validly
ad-hoc signed, and otherwise the status of the first one that is not.
"""
function codesignature_status(path::AbstractString)
    return readmeta(path) do ohs
        for oh in ohs
            status = codesignature_status(oh)
            if status != :adhoc
                return status
            end
        end
        return :adhoc
    end
end
