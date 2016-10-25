using LCIO

LCIO.openStdhep(ARGS[1]) do reader
    println(length(reader))
end

