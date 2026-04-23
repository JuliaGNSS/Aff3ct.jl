module AFF3CT

include("LibAFF3CT.jl")
using .LibAFF3CT

include("common.jl")
include("polar.jl")
include("ldpc.jl")
include("turbo.jl")
include("rsc.jl")

# Abstract types
export AbstractEncoder, AbstractDecoder

# Polar
export generate_frozen_bits_ga, generate_frozen_bits_5g
export PolarEncoder, PolarSCDecoder, PolarSCLDecoder

# LDPC
export LDPCMatrix, LDPCEncoder, LDPCBPDecoder

# Turbo
export TurboEncoder, TurboDecoder

# RSC / Viterbi
export RSCEncoder, ViterbiDecoder

# Common
export encode, decode, encode!, decode!

end # module AFF3CT
