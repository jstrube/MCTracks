using LCIO
using Histograms
using JLD, HDF5

function eCosTheta(mcp)
    energy = getEnergy(mcp)
    p = getMomentum(mcp)
    cosTheta = p[3] / sqrt(p[1]^2 + p[2]^2 + p[3]^2)
    (energy, cosTheta)
end

function plotDirectory(dir, files)
    if !isdir("ECosTheta_Tracks/" * basename(dir))
	mkdir("ECosTheta_Tracks/" * basename(dir))
    end
    outname = "ECosTheta_Tracks/" * basename(dir) * "/" * replace(dir, "/", "_") * ".jld"
    if isfile(outname)
        println("The file $(outname) already exists. THat's bad. Aborting")
    	return
    end
    jldopen(outname, "w") do jldfile
            addrequire(jldfile, Histograms)
	    for file in files
		stdhepfile = joinpath(dir, file)
		lciofile = "lcio/" * replace(file, "stdhep", "slcio")
		# there's a serious mem leak in the stdhepreader...
		isfile(lciofile) && rm(lciofile)
		readstring(`stdhepjob $(stdhepfile) $(lciofile) -1`)
		LCIO.open(lciofile) do reader
		    h2 = H2D(1000, 0, 100, 100, -1, 1)
		    for event in reader
			for mcp in getCollection(event, "MCParticle")
			    if getGeneratorStatus(mcp) != 1
				continue
			    end
			    if getCharge(mcp) == 0
				continue
			    end
			    x, y = eCosTheta(mcp)
			    hfill!(h2, x, y)
			end
		    end
        	    write(jldfile, file, h2)
		end
		rm(lciofile)
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

