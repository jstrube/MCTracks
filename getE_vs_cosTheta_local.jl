using LCIO
using Histograms
using JLD, HDF5

function ptCosTheta(mcp)
    p = getMomentum(mcp)
    cosTheta = p[3] / sqrt(p[1]^2 + p[2]^2 + p[3]^2)
    pt = sqrt(p[1]^2 + p[2]^2)
    (pt, cosTheta)
end

function eCosTheta(mcp)
    energy = getEnergy(mcp)
    p = getMomentum(mcp)
    cosTheta = p[3] / sqrt(p[1]^2 + p[2]^2 + p[3]^2)
    return (energy, cosTheta)
end

function plotDirectory(dir, files)
    if !isdir("PtCosTheta_Tracks_91GeV/" * basename(dir))
        mkdir("PtCosTheta_Tracks_91GeV/" * basename(dir))
    end
    outname = "PtCosTheta_Tracks_91GeV/" * basename(dir) * "/" * replace(dir, "/", "_") * ".jld"
    if isfile(outname)
        println("The file $(outname) already exists. THat's bad. Aborting")
        return
    end
	    for file in files
		if ! endswith(file, ".slcio")
		    continue
                end
                LCIO.open(joinpath(dir,file)) do reader
                    h2 = H2D(1000, 0, 100, 100, -1, 1)
                    for event in reader
                        for mcp in getCollection(event, "MCParticle")
                            if getGeneratorStatus(mcp) != 1
                                continue
                            end
                            if abs(getPDG(mcp)) in [12, 14, 16, 22, 111, 130, 310, 311]
                                continue
                            end
                            x, y = ptCosTheta(mcp)
                            hfill!(h2, x, y)
                        end
                    end
    		    jldopen(outname, "w") do jldfile
                        write(jldfile, file, h2)
                    end
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
