using JLD
using Histograms
using Plots
using LaTeXStrings

# function plot(h::Histograms.Histogram2D)
#     xs = h.binEdges[1][10:51]
#     ys = h.binEdges[2][20:end-20]
#     z = h.weights[10:52, 20:end-21]
#     heatmap(ys,xs,z)
#     savefig("sum.png")
# end

# 500 GeV cross sections:
# - might be a bit off because of e+ e- luminosity being used, not gamma gamma cross section
# - polarization?

# 91 GeV cross section, with polarized (80, 30) beams: 6.0545645E+07
# files do not use the proper OPAL tune


xs500 = load("sumHist_pt.jld")
xs91 = load("PtCosTheta_Tracks_91GeV/91_GeV_slcio/91_GeV_slcio.jld")

# multiply with cross section according to Whizard
println("91 GeV")
println("Unweighted: ", sum(xs91["Zqq.slcio"].weights), "\t", sum(xs91["Zqq.slcio"].entries))
println("weight: ", 6.0545645E+07 / 1e7)
xs91["Zqq.slcio"].weights *= (6.0545645E+07 / 1e7)
println("Weighted: ", sum(xs91["Zqq.slcio"].weights[12:end,2:end-1]), "\tnTracks/event: ", sum(xs91["Zqq.slcio"].weights[12:end,2:end-1])/6.0545645E+07)

println("500 GeV")
println("Weighted: ", sum(xs500["500GeV_sum"].weights[12:end,2:end-1]), "\ttracks: ", sum(xs500["500GeV_sum"].weights[12:end,2:end-1]) / 3.0961957740794774e6)

minE = 1
# integrate the plots from minE GeV to 100 GeV
w1 = sum(xs500["500GeV_sum"].weights[10minE+2:end,2:end-1], 1)
w2 = sum(xs91["Zqq.slcio"].weights[10minE+2:end,2:end-1], 1)
plot(linspace(-1,1,100), w1[:], label="500 GeV")
plot(linspace(-1,1,100), w2[:], label="91 GeV, 1% peak luminosity")
savefig("h.png")

# # log scale
# plot(linspace(-1,1,100),w1[:]./w2[:],ylim=(1e-3,1),leg=false,xlabel=L"\cos\theta",ylabel="#tracks (500 GeV) / #tracks (91 GeV)", yticks=([0.001,0.02, 0.05, 0.1, 0.2, 0.5, 0.7, 1.0],[0.001,0.02, 0.05, 0.1, 0.2, 0.5, 0.7, 1.0]))
# yaxis!(:log10)
# title!("Ratio of #tracks at a 500 GeV \n and a 91 GeV ILC (assuming the same luminosity)")
# savefig("ratios_1GeV_log.png")

# number of tracks in a bin in the central region?
xvals = 10:1:50
tracksum(hist) = [sum(hist.weights[cutoff+2:end, 50:51],1)[:][1] for cutoff in xvals]
plot(xvals/10, tracksum(xs500["500GeV_sum"])./tracksum(xs91["Zqq.slcio"]), leg=false, ylim=(0, 0.008))
title!("Ratio of #tracks in the central detector at a 500 GeV \n and a 91 GeV ILC (assuming the same luminosity)")
xlabel!("minimum track pt (GeV)")
savefig("plot.png")
