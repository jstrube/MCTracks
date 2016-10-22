using Histograms
using JLD
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

# this function groups the different processes and scales according to a given polarization
# what we need is a dictionary for each process that contains the four possible polarization states
function polarizationCombinations()
    polarizationCombos = Dict{String, Dict{String, Float64}}()
    for line in readlines(open("500-TDR_ws.list"))
        if length(line) < 2
            continue
        end
        # the file names are unfortunately not all following convention
        # the different pieces can come in different orders, that's why we need three different regexes, rather than just one.
        if ! endswith(line, ".stdhep\n")
            continue
        end
        process = match(r"\.P([A-Za-z0-9_-]+)\.", line)[1]
        pol = match(r"\.(e.\.p.)", line)[1]
        id = parse(Int64, match(r"\.I(\d+)\.", line)[1])
        if ! haskey(polarizationCombos, process)
            polarizationCombos[process] = Dict{String, Float64}()
            for key in ("eL.pR", "eR.pL", "eL.pL", "eR.pR", "eW.pB", "eW.pW", "eB.pB", "eB.pW", "eB.pR", "eB.pL", "eW.pR", "eW.pL", "eL.pB", "eL.pW", "eR.pB", "eR.pW")
                polarizationCombos[process][key] = 0.0
            end
        end
        polarizationCombos[process][pol] = crossSections[id]
    end
    return polarizationCombos
end

# # we're simply summing the electron cross sections and the photon cross sections for each proces. The "wrong" cross sections are always 0, so we're fine.
# processList = polarizationCombinations()
# σ = processList[process]
# 0 photons
# thisXS = 0.90*0.65*σ["eL.pR"] + 0.90*0.35*σ["eL.pL"] + 0.1*0.65*σ["eR.pR"] + 0.1*0.35*σ["eR.pL"]
# 1 photon
# thisXS += 0.90*σ["eL.pB"] + 0.90*σ["eL.pW"] + 0.1*σ["eR.pW"] + 0.1*σ["eR.pB"]
# 2 photons
# thisXS += σ["eB.pB"] + σ["eW.pB"] + σ["eB.pW"] + σ["eW.pW"]

# start with an empty histogram
sumHist = H2D(1000, 0, 100, 100, -1, 1)
# now read the histograms
for (root, dirs, files) in walkdir("ECosTheta_Tracks")
    for f in files
        thisfile = joinpath(root, f)
        jldopen(thisfile, "r") do histofile
            for histo in names(histofile)
                h = read(histofile, histo)
                id = parse(Int64, match(r"\.I(\d+)\.", histo)[1])
                process = match(r"\.P([A-Za-z0-9_-]+)\.", line)[1]
                pol = match(r"\.(e.\.p.)", line)[1]
                # polarization-weighted cross section
                polFactor = 1.
                if contains(pol, "eR") polFactor *= 0.1 end
                if contains(pol, "eL") polFactor *= 0.9 end
                if contains(pol, "pR") polFactor *= 0.65 end
                if contains(pol, "pL") polFactor *= 0.35 end
                h.weights *= (polfactor * crossSections[id])
                sumHist.weights += h.weights
                sumHist.entries += h.entries
            end
        end
    end
end
jldopen("sumHist.jld", "w") do file
    write(file, "500GeV_sum", sumHist)  # alternatively, say "@write file A"
end
