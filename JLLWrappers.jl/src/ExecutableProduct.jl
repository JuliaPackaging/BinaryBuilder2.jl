# Things that are useful to know across platforms
if Sys.iswindows()
    const LIBPATH_env = "PATH"
    const LIBPATH_default = ""
    const pathsep = ';'
elseif Sys.isapple()
    const LIBPATH_env = "DYLD_FALLBACK_LIBRARY_PATH"
    const LIBPATH_default = "~/lib:/usr/local/lib:/lib:/usr/lib"
    const pathsep = ':'
else
    const LIBPATH_env = "LD_LIBRARY_PATH"
    const LIBPATH_default = ""
    const pathsep = ':'
end

function adjust_ENV!(env::Dict, PATH::String, LIBPATH::String, adjust_PATH::Bool, adjust_LIBPATH::Bool)
    if adjust_LIBPATH
        LIBPATH_base = get(env, LIBPATH_env, expanduser(LIBPATH_default))
        if !isempty(LIBPATH_base)
            env[LIBPATH_env] = string(LIBPATH, pathsep, LIBPATH_base)
        else
            env[LIBPATH_env] = LIBPATH
        end
    end
    if adjust_PATH && (LIBPATH_env != "PATH" || !adjust_LIBPATH)
        if adjust_PATH
            if !isempty(get(env, "PATH", ""))
                env["PATH"] = string(PATH, pathsep, env["PATH"])
            else
                env["PATH"] = PATH
            end
        end
    end
    return env
end

function executable_product_definition(jb::JLLBlocks, artifact, product)
    var_name, path_var_name, lazy_path_var_name = gen_lazy_artifact_path(jb, artifact, product)

    push!(jb.top_level_blocks, quote
        function $(var_name)(; adjust_PATH::Bool = true, adjust_LIBPATH::Bool = true)
            env = Base.invokelatest(
                JLLWrappers.adjust_ENV!,
                copy(ENV),
                PATH[],
                LIBPATH[],
                adjust_PATH,
                adjust_LIBPATH,
            )
            return Cmd(Cmd([string($(lazy_path_var_name))]); env)
        end
    end)
end
