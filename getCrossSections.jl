crossSections = Dict{Int64, Float64}()
# read existing cross sections
for line in readlines(open("xs500GeV"))
    if length(line) < 2
        continue
    end
    fields = split(line)
    if length(fields) != 2
        continue
    end
    crossSections[parse(Int64, fields[1])] = parse(Float64, fields[2])
end
for line in readlines(open(ARGS[1]))
    if !endswith(line, "stdhep\n")
	continue
    end
    line = replace(line[1:end-1], "./", "/ilc/prod/ilc/mc-dbd/generated/500-TDR_ws/")
    id = r"\.I(\d+)\."
    if haskey(crossSections, parse(Int64, match(id, line)[1]))
        continue
    end
    metadata = readstring(`dirac-ilc-get-info -f $(line)`)
    xs = r"CrossSection  : ([0-9.]+) fb\+"
    xs2 = r"'XSection': '([0-9.]+)'"
    if match(xs, metadata) != nothing
        println(match(id, line)[1], "\t", match(xs, metadata)[1])
    elseif match(xs2, metadata) != nothing
	println(match(id, line)[1], "\t", match(xs2, metadata)[1])
    else 
	println(match(id, line)[1])
	#println(line)
        #println(metadata)
    end
end
