using LCIO
using Histograms
using JLD, HDF5

function plotDirectory(dir, files)
    open("nEvents", "w") do outdict
    for file in files
	stdhepfile = joinpath(dir, file)
	# there's a serious mem leak in the stdhepreader...
	x = readstring(`julia readNEvents.jl $(stdhepfile)`)
	println(stdhepfile, "\t", x)
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

