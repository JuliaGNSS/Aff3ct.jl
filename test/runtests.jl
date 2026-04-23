using Test

@testset "AFF3CT.jl" begin
    include("test_polar.jl")
    include("test_turbo.jl")
    include("test_ldpc.jl")
    include("test_rsc.jl")
end
