# ── RSC Encoder ──────────────────────────────────────────────────────

"""
    RSCEncoder(K, N; poly=nothing)

Recursive Systematic Convolutional (RSC) encoder with trellis termination.

Output is interleaved: `[s₀,p₀, s₁,p₁, …, tail_s₀,tail_p₀, …]`.

- `K`: information bits
- `N`: codeword length (`2*(K + n_ff)` for rate-1/2 with trellis termination)
- `poly`: generator polynomial pair in octal (e.g., `[05, 07]`). Default: `[05, 07]`.
"""
mutable struct RSCEncoder <: AbstractEncoder
    handle::Ptr{Cvoid}
    K::Int
    N::Int

    function RSCEncoder(K::Integer, N::Integer;
                        poly::Union{Nothing,Vector{<:Integer}}=nothing)
        p = poly === nothing ? nothing : Cint.(poly)
        handle = LibAFF3CT.rsc_encoder_create(K, N, p)
        LibAFF3CT.attach_finalizer!(new(handle, Int(K), Int(N)),
                                    LibAFF3CT.rsc_encoder_destroy)
    end
end

_encode_impl!(enc::RSCEncoder, U_K, X_N) = LibAFF3CT.rsc_encode!(enc.handle, U_K, X_N)

# ── Viterbi Decoder ─────────────────────────────────────────────────

"""
    ViterbiDecoder(K, N; poly=nothing)

Viterbi (SIHO) decoder for RSC codes with trellis termination.

Expects interleaved LLRs matching [`RSCEncoder`](@ref) output format.

- `K`: information bits
- `N`: codeword length (must match the RSC encoder)
- `poly`: generator polynomial pair in octal. Default: `[05, 07]`.
"""
mutable struct ViterbiDecoder <: AbstractDecoder
    handle::Ptr{Cvoid}
    K::Int
    N::Int

    function ViterbiDecoder(K::Integer, N::Integer;
                            poly::Union{Nothing,Vector{<:Integer}}=nothing)
        p = poly === nothing ? nothing : Cint.(poly)
        handle = LibAFF3CT.viterbi_decoder_create(K, N, p)
        LibAFF3CT.attach_finalizer!(new(handle, Int(K), Int(N)),
                                    LibAFF3CT.viterbi_decoder_destroy)
    end
end

_decode_impl!(dec::ViterbiDecoder, Y_N, V_K) = LibAFF3CT.viterbi_decode!(dec.handle, Y_N, V_K)
