using Test

@testset verbose=true "AFF3CT.jl" begin
    include("test_polar.jl")
    include("test_turbo.jl")
    include("test_ldpc.jl")
    include("test_rsc.jl")
    include("test_conv.jl")
end
