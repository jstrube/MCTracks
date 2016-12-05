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

# 91 GeV cross section, with polarized (80, 30) beams:
# Z -> qq: 6.0545645E+07
# Z -> mu mu: 3.0060166E+06
# unpolarized:
# Z -> qq: 4.1011198E+07
# Z -> mu mu: 2.0393335E+06

# files do not use the proper OPAL tune

ZqqXS = 3.05E+07
ZmumuXS = ZqqXS / 21

xs500 = load("sumHist_pt.jld")
xs91 = load("PtCosTheta_Tracks_91GeV/91_GeV_slcio/91_GeV_slcio.jld")
xs91_tau = load("PtCosTheta_Tracks_91GeV/91_GeV_taus/91_GeV_taus.jld")
xs91_mu = load("PtCosTheta_Tracks_91GeV/91_GeV_muons/91_GeV_muons.jld")

# multiply with cross section according to Whizard
println("91 GeV")
println("Unweighted: ", sum(xs91["Zqq.slcio"].weights), "\t", sum(xs91["Zqq.slcio"].entries))
println("weight: ", ZqqXS / 1e7)
xs91["Zqq.slcio"].weights *= (ZqqXS / 1e7)
# muons
xs91["Zqq.slcio"].weights += xs91_mu["Zmumu_91_Whizard.slcio"].weights * (ZmumuXS / 1e5)
# electrons have the same number as muons, but are harder to generate
xs91["Zqq.slcio"].weights += xs91_mu["Zmumu_91_Whizard.slcio"].weights * (ZmumuXS / 1e5)
# taus
xs91["Zqq.slcio"].weights += xs91_tau["Ztautau_91_Whizard.slcio"].weights * (ZmumuXS / 1e5)

println("Weighted: ", sum(xs91["Zqq.slcio"].weights[12:end,2:end-1]), "\tnTracks/event: ", sum(xs91["Zqq.slcio"].weights[12:end,2:end-1])/ZqqXS)
println("Weighted: ", sum(xs91["Zqq.slcio"].weights[:,33:end-32]))

println("500 GeV")
println("Weighted: ", sum(xs500["500GeV_sum"].weights[12:end,2:end-1]), "\ttracks: ", sum(xs500["500GeV_sum"].weights[12:end,2:end-1]) / 3.0961957740794774e6)
println("SiD Barrel: R(Layer 5): 1.22m, half-length(z): 304.5/2 --> |cosTheta| = 0.625")
println("Number of tracks > 2 GeV in that barrel region: ", sum(xs500["500GeV_sum"].weights[22:end,33:end-32]))
println("Number of tracks > 0 GeV in |cosTheta|<0.4: ", sum(xs500["500GeV_sum"].weights[:,32:end-31]))
println("Number of tracks > 0 GeV in |cosTheta|<0.8: ", sum(xs500["500GeV_sum"].weights[:,12:end-11]))
println("Number of tracks > 0 GeV in |cosTheta|<0.96: ", sum(xs500["500GeV_sum"].weights[:,6:end-5]))

minE = 2
cosThetaRange = 0.7
# convert this to a bin with the knowledge that the bins are linspace(-1,1,101)
cosThetaBin = 0#convert(Int64, round(100(1.0-cosThetaRange)/2))
# for the upper bin, we need to subtract 1, because the bin edges are always the left edges, and the upper edge is the right edge
# integrate the plots from minE GeV to 100 GeV
w1 = sum(xs500["500GeV_sum"].weights[10minE+2:end,2+cosThetaBin:end-1-cosThetaBin], 1)
w2 = sum(xs91["Zqq.slcio"].weights[10minE+2:end,2+cosThetaBin:end-1-cosThetaBin], 1)
println(size(w1), "\t", xs500["500GeV_sum"].binEdges[2][101])
plot(linspace(-1,1,101), w1[:], linetype=:steppost,tickfont=font(12, "Liberation Sans"), guidefont=font(14, "Liberation Sans"), titlefont=font(16, "Liberation Serif"))
savefig("hist500.pdf")
plot(linspace(-1,1,101), w1[:], linetype=:steppre,tickfont=font(12, "Liberation Sans"), guidefont=font(14, "Liberation Sans"), titlefont=font(16, "Liberation Serif"))
savefig("hist91.pdf")

# The x-axis must have the correct spacing, we'll add one tick in x, because the last bin *ends* at 1.0, it doesn't *start* at 1.0. "steppost" takes care of this.
# # log scale
plot(linspace(-1,1,101),w1[:]./w2[:],ylim=(1e-3,1),linetype=:steppost, leg=false,xlabel=L"\cos\theta",ylabel="#tracks (500 GeV) / #tracks (91 GeV)", yticks=([0.001,0.02, 0.05, 0.1, 0.2, 0.5, 0.7, 1.0], [0.001,0.02, 0.05, 0.1, 0.2, 0.5, 0.7, 1.0]), tickfont=font(12, "Liberation Sans"), guidefont=font(14, "Liberation Sans"), titlefont=font(16, "Liberation Serif"))
yaxis!(:log10)
title!("Ratio of #tracks at a 500 GeV \n and a 91 GeV ILC (assuming the same luminosity)")
savefig("ratios_2GeV_log.pdf")

# number of tracks in a bin in the central region?
xvals = 10:1:450

cosThetaRange = 0.1
# convert this to a bin with the knowledge that the bins are linspace(-1,1,100)
cosThetaBin = convert(Int64, round(100(1.0-cosThetaRange)/2))
tracksum(hist) = [sum(hist.weights[cutoff+2:end, 2+cosThetaBin:end-cosThetaBin-1],1)[:][1] for cutoff in xvals]
plot(xvals/10, tracksum(xs500["500GeV_sum"])./tracksum(xs91["Zqq.slcio"]), leg=false, tickfont=font(12, "Liberation Sans"), guidefont=font(14, "Liberation Sans"), titlefont=font(16, "Liberation Serif"))
title!("ratio of #tracks with" * L"|\cos\theta|<0.1"*" vs min pt")
xlabel!("minimum track pt (GeV)")
savefig("plot.pdf")
# plot(xvals/10, tracksum(xs500["500GeV_sum"])./sum(xs500["500GeV_sum"].weights[2+2:end, 2+cosThetaBin:end-cosThetaBin-1],1)[:][1], leg=false, tickfont=font(12, "Liberation Sans"), guidefont=font(14, "Liberation Sans"), titlefont=font(16, "Liberation Serif"))
# title!("#tracks with " * L"|\cos\theta|<0.1"*" at a 500 GeV ILC")
# xlabel!("minimum track pt (GeV)")
# savefig("plot.pdf")
