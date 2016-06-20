function show(io::IO,r::RObject)
    println(io,typeof(r))
    rprint(io,r.p)
    # ggplot2's plot is displayed after `print` function is invoked,
    # so we have to clear any displayed plots.
    isdefined(Main, :IJulia) && Main.IJulia.inited && ijulia_displayplots()
end

global const printBuffer = PipeBuffer()
global const errorBuffer = PipeBuffer()

function writeConsoleEx(buf::Ptr{UInt8},buflen::Cint,otype::Cint)
    if otype == 0
        Compat.unsafe_write(printBuffer, buf, buflen)
    else
        Compat.unsafe_write(errorBuffer, buf, buflen)
    end
    return nothing
end

# mainly use to prevent eventCallBack stealing rprint output
global PrintBufferLocked = false

function flush_printBuffer(io::IO)
    global PrintBufferLocked
    # dump printBuffer's content which it is not locked
    if ! PrintBufferLocked
        nb_available(printBuffer) != 0  && write(io, takebuf_string(printBuffer))
    end
    nothing
end

function eventCallBack()
    # dump printBuffer STDOUT when available
    flush_printBuffer(STDOUT)
    nothing
end

function askYesNoCancel(prompt::Ptr{Cchar})
    println(isdefined(Core, :String) ? String(prompt) : bytestring(prompt))
	query = readline(STDIN)
	c = uppercase(query[1])
	r::Cint
	r = (c=='Y' ? 1 : c=='N' ? -1 : 0)
    return r
end

if Compat.is_windows()
    """
        RStart

    This type mirrors `structRstart` in `R_ext/RStartup.h`. It is used to change the IO behaviour on Windows.
    """
    type RStart # mirror structRstart in R_ext/RStartup.h
        R_Quiet::Cint
        R_Slave::Cint
        R_Interactive::Cint
        R_Verbose::Cint
        LoadSiteFile::Cint
        LoadInitFile::Cint
        DebugInitFile::Cint
        RestoreAction::Cint
        SaveAction::Cint
        vsize::Csize_t
        nsize::Csize_t
        max_vsize::Csize_t
        max_nsize::Csize_t
        ppsize::Csize_t
        NoRenviron::Cint
        rhome::Ptr{Cchar}
        home::Ptr{Cchar}
        ReadConsole::Ptr{Void}
        WriteConsole::Ptr{Void}
        CallBack::Ptr{Void}
        ShowMessage::Ptr{Void}
        YesNoCancel::Ptr{Void}
        Busy::Ptr{Void}
        CharacterMode::Cint
        WriteConsoleEx::Ptr{Void}
    end
    RStart() = RStart(0,0,0,0,0,
                      0,0,0,0,0,
                      0,0,0,0,0,
                      C_NULL,C_NULL,
                      C_NULL,C_NULL,C_NULL,C_NULL,
                      C_NULL,C_NULL,2,C_NULL)

end
