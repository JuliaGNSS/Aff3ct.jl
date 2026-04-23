# ── Frozen bits generation ───────────────────────────────────────────

"""
    generate_frozen_bits_ga(K, N; design_snr=0.0) -> Vector{Bool}

Generate frozen bit positions using Gaussian Approximation (GA).
Returns a `Vector{Bool}` of length `N` where `true` = frozen, `false` = info.
"""
function generate_frozen_bits_ga(K::Integer, N::Integer; design_snr::Real=0.0)
    gen = LibAFF3CT.frozenbits_gen_ga_create(K, N, design_snr)
    try
        fb = Vector{Cint}(undef, N)
        LibAFF3CT.frozenbits_gen_generate!(gen, fb)
        return Bool.(fb)
    finally
        LibAFF3CT.frozenbits_gen_destroy(gen)
    end
end

"""
    generate_frozen_bits_5g(K, N) -> Vector{Bool}

Generate frozen bit positions using the 5G-NR standard tables (N ≤ 1024).
"""
function generate_frozen_bits_5g(K::Integer, N::Integer)
    gen = LibAFF3CT.frozenbits_gen_5g_create(K, N)
    try
        fb = Vector{Cint}(undef, N)
        LibAFF3CT.frozenbits_gen_generate!(gen, fb)
        return Bool.(fb)
    finally
        LibAFF3CT.frozenbits_gen_destroy(gen)
    end
end

# ── Polar Encoder ────────────────────────────────────────────────────

"""
    PolarEncoder(K, N, frozen_bits::AbstractVector{Bool})

Systematic polar encoder for codeword length `N` and `K` information bits.
`frozen_bits` is a `Vector{Bool}` of length `N` (true = frozen).
"""
mutable struct PolarEncoder <: AbstractEncoder
    handle::Ptr{Cvoid}
    K::Int
    N::Int

    function PolarEncoder(K::Integer, N::Integer, frozen_bits::AbstractVector{Bool})
        handle = LibAFF3CT.polar_encoder_create(K, N, Cint.(frozen_bits))
        LibAFF3CT.attach_finalizer!(new(handle, Int(K), Int(N)),
                                    LibAFF3CT.polar_encoder_destroy)
    end
end

_encode_impl!(enc::PolarEncoder, U_K, X_N) = LibAFF3CT.polar_encode!(enc.handle, U_K, X_N)

# ── Polar SC Decoder ─────────────────────────────────────────────────

"""
    PolarSCDecoder(K, N, frozen_bits::AbstractVector{Bool})

Successive Cancellation (SC) decoder for polar codes.
"""
mutable struct PolarSCDecoder <: AbstractDecoder
    handle::Ptr{Cvoid}
    K::Int
    N::Int

    function PolarSCDecoder(K::Integer, N::Integer, frozen_bits::AbstractVector{Bool})
        handle = LibAFF3CT.polar_sc_decoder_create(K, N, Cint.(frozen_bits))
        LibAFF3CT.attach_finalizer!(new(handle, Int(K), Int(N)),
                                    LibAFF3CT.polar_sc_decoder_destroy)
    end
end

_decode_impl!(dec::PolarSCDecoder, Y_N, V_K) = LibAFF3CT.polar_sc_decode!(dec.handle, Y_N, V_K)

# ── Polar SCL Decoder ────────────────────────────────────────────────

"""
    PolarSCLDecoder(K, N, L, frozen_bits::AbstractVector{Bool})

Successive Cancellation List (SCL) decoder with list size `L`.
"""
mutable struct PolarSCLDecoder <: AbstractDecoder
    handle::Ptr{Cvoid}
    K::Int
    N::Int
    L::Int

    function PolarSCLDecoder(K::Integer, N::Integer, L::Integer, frozen_bits::AbstractVector{Bool})
        handle = LibAFF3CT.polar_scl_decoder_create(K, N, L, Cint.(frozen_bits))
        LibAFF3CT.attach_finalizer!(new(handle, Int(K), Int(N), Int(L)),
                                    LibAFF3CT.polar_scl_decoder_destroy)
    end
end

_decode_impl!(dec::PolarSCLDecoder, Y_N, V_K) = LibAFF3CT.polar_scl_decode!(dec.handle, Y_N, V_K)

Base.show(io::IO, dec::PolarSCLDecoder) =
    print(io, "PolarSCLDecoder(K=", dec.K, ", N=", dec.N, ", L=", dec.L, ")")
