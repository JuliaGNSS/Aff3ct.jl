# ── Feedforward Convolutional Encoder ────────────────────────────────

"""
    ConvEncoder(K, N, poly)

Feedforward (non-systematic) convolutional encoder with trellis termination.

Constraint: `N == length(poly) * (K + n_ff)` where `n_ff = floor(log2(max(poly)))`.

- `K`: information bits
- `N`: codeword length
- `poly`: generator polynomials in octal, rate = `1 / length(poly)`. Required.

# Example

Galileo E1B (`poly = [0o171, 0o133]`, constraint length 7 → `n_ff = 6`),
`K = 64` → `N = 2 * (64 + 6) = 140`:

```julia
enc = ConvEncoder(64, 140, [0o171, 0o133])
```
"""
mutable struct ConvEncoder <: AbstractEncoder
    handle::Ptr{Cvoid}
    K::Int
    N::Int

    function ConvEncoder(K::Integer, N::Integer, poly::AbstractVector{<:Integer})
        handle = LibAFF3CT.conv_encoder_create(K, N, Cint.(collect(poly)))
        LibAFF3CT.attach_finalizer!(new(handle, Int(K), Int(N)),
                                    LibAFF3CT.conv_encoder_destroy)
    end
end

_encode_impl!(enc::ConvEncoder, U_K, X_N) = LibAFF3CT.conv_encode!(enc.handle, U_K, X_N)

# ── Viterbi Decoder for feedforward convolutional codes ──────────────

"""
    ConvViterbiDecoder(K, N, poly)

Viterbi (SIHO) decoder for feedforward convolutional codes with trellis
termination. Distinct from [`ViterbiDecoder`](@ref) (which decodes RSC codes)
because the trellis differs between the two code families.

Expects interleaved LLRs matching [`ConvEncoder`](@ref) output format.
"""
mutable struct ConvViterbiDecoder <: AbstractDecoder
    handle::Ptr{Cvoid}
    K::Int
    N::Int

    function ConvViterbiDecoder(K::Integer, N::Integer, poly::AbstractVector{<:Integer})
        handle = LibAFF3CT.conv_viterbi_decoder_create(K, N, Cint.(collect(poly)))
        LibAFF3CT.attach_finalizer!(new(handle, Int(K), Int(N)),
                                    LibAFF3CT.conv_viterbi_decoder_destroy)
    end
end

_decode_impl!(dec::ConvViterbiDecoder, Y_N, V_K) =
    LibAFF3CT.conv_viterbi_decode!(dec.handle, Y_N, V_K)
