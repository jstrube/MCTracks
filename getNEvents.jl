using LCIO
using Histograms
using JLD, HDF5

nEvents = Dict{String, Int64}()
for line in readlines(open("nEvents"))
    if length(line) < 2
        continue
    end
    fields = split(line)
    nEvents[basename(fields[1])] = parse(Int64, fields[2])
end

function plotDirectory(dir, files)
    open("nEvents2", "a") do outdict
    for file in files
	if !endswith(file, "stdhep")
            continue
        end
        if haskey(nEvents, file)
            continue
        end
	stdhepfile = joinpath(dir, file)
	# there's a serious mem leak in the stdhepreader...
	# that's why we read the file in a separate process. 
	# Otherwise, we run out of memory
	x = readstring(`julia readNEvents.jl $(stdhepfile)`)
	print(outdict, stdhepfile * "\t" * x)
    end
    end
    return
end

dir = "/pic/projects/grid/ilc/prod/ilc/mc-dbd/generated/"
if length(ARGS) > 0
    dir = ARGS[1]
end
for (root, dirs, files) in walkdir(dir)
    plotDirectory(root, files)
end

