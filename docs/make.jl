using Documenter
using AFF3CT

makedocs(;
    modules=[AFF3CT],
    sitename="AFF3CT.jl",
    authors="Soeren Schoenbrod and contributors",
    pages=[
        "Home" => "index.md",
        "Polar Codes" => "polar.md",
        "Turbo Codes" => "turbo.md",
        "LDPC Codes" => "ldpc.md",
        "Convolutional Codes (RSC)" => "rsc.md",
        "Comparison" => "comparison.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaGNSS/AFF3CT.jl",
    devbranch="main",
    push_preview=true,
)
