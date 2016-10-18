using JLD
using Plots
using Histograms
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

minE = 1

xs500 = load("sumHist.jld")
xs91 = load("91_GeV_slcio.jld")
xs91["Zqq.slcio"].weights *= 6.0545645E+07

# integrate the plots from 1 GeV to 100 GeV
w1 = sum(xs500["500GeV_sum"].weights[20minE+1:end,:], 1)
w2 = sum(xs91["Zqq.slcio"].weights[20minE+1:end,:], 1)
plot(linspace(-1,1,102),w1[:]./w2[:],ylim=(1e-3,1),leg=false,xlabel=L"\cos\theta",ylabel=L"$\sigma$(500 GeV) / $\sigma$(91 GeV)")
yaxis!(:log10)
savefig("ratios_log.png")
