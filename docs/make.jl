using Documenter
using Aff3ct

makedocs(;
    modules=[Aff3ct],
    sitename="Aff3ct.jl",
    authors="Soeren Schoenbrod and contributors",
    pages=[
        "Home" => "index.md",
        "Polar Codes" => "polar.md",
        "Turbo Codes" => "turbo.md",
        "LDPC Codes" => "ldpc.md",
        "Convolutional Codes (RSC)" => "rsc.md",
        "Convolutional Codes (Feedforward)" => "conv.md",
        "Comparison" => "comparison.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaGNSS/Aff3ct.jl",
    devbranch="main",
    push_preview=true,
)
