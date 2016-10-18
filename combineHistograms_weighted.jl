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
                h.weights *= crossSections[id]
                sumHist.weights += h.weights
                sumHist.entries += h.entries
            end
        end
    end
end
jldopen("sumHist.jld", "w") do file
    write(file, "500GeV_sum", sumHist)  # alternatively, say "@write file A"
end
