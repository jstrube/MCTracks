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

nEvents = Dict{String, Int64}()
for line in readlines(open("nEvents"))
    if length(line) < 2
        continue
    end
    fields = split(line)
    nEvents[basename(fields[1])] = parse(Int64, fields[2])
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
sumHist = Dict{Int64, Histograms.Histogram2D}()
# to keep track of the different process weights
weightList = Dict{Int64, Any}()
# to keep track of the different polarization states for a given process
processList = Dict{String, Set{Int64}}()
# to keep track of the different cross sections and polarizations
polarizationList = Dict{Int64, Float64}()

# now read the histograms
for (root, dirs, files) in walkdir("PtCosTheta_Tracks")
    for f in files
        thisfile = joinpath(root, f)
        jldopen(thisfile, "r") do histofile
            for histo in names(histofile)
                h = read(histofile, histo)
                id = parse(Int64, match(r"\.I(\d+)\.", histo)[1])
                process = match(r"\.P([A-Za-z0-9_-]+)\.", histo)[1]
                pol = match(r"\.(e.\.p.)", histo)[1]
                # skip the aaddhad process. The weight is just too high
                if process == "aaddhad"
                    continue
                end
                # polarization-weighted cross section
                polFactor = 1.
                if contains(pol, "eR")
                    polFactor *= 0.1
                elseif contains(pol, "eL")
                    polFactor *= 0.9
                end
                if contains(pol, "pR")
                    polFactor *= 0.65
                elseif contains(pol, "pL")
                    polFactor *= 0.35
                end
                if ! haskey(sumHist, id)
                    sumHist[id] = H2D(1000, 0, 100, 100, -1, 1)
                end
                add!(sumHist[id], h)
                if ! haskey(weightList, id)
                    weightList[id] = (0, 0, 0)
                end
                v = weightList[id]
                weightList[id] = (v[1]+nEvents[histo], v[2]+sum(h.entries), v[3]+sum(h.entries[21:end, 17:end-16])) # 2+ GeV, |cosTheta| < 0.7
                if ! haskey(processList, process)
                    processList[process] = Set{Int64}(id)
                else
                    push!(processList[process], id)
                end
                if ! haskey(polarizationList, id)
                    polarizationList[id] = polFactor*crossSections[id]
                end
            end
        end
    end
end
@printf("%-16s %16s %16s %16s %16s %16s\n", "Process", "#events", "pol × XS", "weight/event", "#tracks/event", "2 GeV, central")
using DataStructures
for (k,val) in SortedDict(processList)
    pol = sum(polarizationList[id] for id in processList[k])
    v = [0, 0, 0]
    for id in processList[k]
        w = weightList[id]
        v[1] += w[1]
        v[2] += w[2]
        v[3] += w[3]
    end
    @printf("%-16s %16d %16.3e %16.3f %16.3f %16.3f\n", k, v[1], pol, pol/v[1], v[2]/v[1], v[3]/v[1])
end

totalSum = H2D(1000, 0, 100, 100, -1, 1)
for (k, v) in sumHist
    v.weights *= polarizationList[k]
    v.weights /= weightList[k][1]
    add!(totalSum, v)
end
nEventsTotal = sum(value[1] for (process, value) in weightList)
println("In total, we processed ", nEventsTotal, " events")
totalXS = sum(v for (k, v) in polarizationList)
println("The total cross section processed is ", totalXS, " fb")
totalTracks = sum(totalSum.weights)
println("This results in ", totalTracks, " tracks")

jldopen("sumHist_pt.jld", "w") do file
    write(file, "500GeV_sum", totalSum)  # alternatively, say "@write file A"
end
