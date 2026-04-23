# ── Turbo Encoder ────────────────────────────────────────────────────

const TURBO_INTERLEAVERS = (:LTE, :RANDOM, :NO)

function _check_interleaver(interleaver::Symbol)
    interleaver in TURBO_INTERLEAVERS || throw(ArgumentError(
        "interleaver must be one of $(TURBO_INTERLEAVERS), got :$interleaver"))
    return String(interleaver)
end

"""
    TurboEncoder(K, N; interleaver=:LTE, poly=nothing)

Turbo encoder using two RSC component encoders.

- `K`: information bits
- `N`: codeword length (must be consistent with RSC + tail bits)
- `interleaver`: `:LTE`, `:RANDOM`, or `:NO` (identity)
- `poly`: generator polynomial pair in octal (e.g., `[013, 015]`). Default: `[013, 015]`.
"""
mutable struct TurboEncoder <: AbstractEncoder
    handle::Ptr{Cvoid}
    K::Int
    N::Int

    function TurboEncoder(K::Integer, N::Integer;
                          interleaver::Symbol=:LTE,
                          poly::Union{Nothing,Vector{<:Integer}}=nothing)
        interleaver_str = _check_interleaver(interleaver)
        p = poly === nothing ? nothing : Cint.(poly)
        handle = LibAFF3CT.turbo_encoder_create(K, N, interleaver_str, p)
        LibAFF3CT.attach_finalizer!(new(handle, Int(K), Int(N)),
                                    LibAFF3CT.turbo_encoder_destroy)
    end
end

_encode_impl!(enc::TurboEncoder, U_K, X_N) = LibAFF3CT.turbo_encode!(enc.handle, U_K, X_N)

# ── Turbo Decoder ────────────────────────────────────────────────────

"""
    TurboDecoder(K, N; num_iterations=6, interleaver=:LTE, poly=nothing, buffered_encoding=true)

Standard turbo decoder using two BCJR SISO component decoders.
`num_iterations` is the number of turbo iterations.
"""
mutable struct TurboDecoder <: AbstractDecoder
    handle::Ptr{Cvoid}
    K::Int
    N::Int

    function TurboDecoder(K::Integer, N::Integer;
                          num_iterations::Integer=6,
                          interleaver::Symbol=:LTE,
                          poly::Union{Nothing,Vector{<:Integer}}=nothing,
                          buffered_encoding::Bool=true)
        interleaver_str = _check_interleaver(interleaver)
        p = poly === nothing ? nothing : Cint.(poly)
        handle = LibAFF3CT.turbo_decoder_create(K, N, num_iterations, interleaver_str, p;
                                                 buffered_encoding=buffered_encoding)
        LibAFF3CT.attach_finalizer!(new(handle, Int(K), Int(N)),
                                    LibAFF3CT.turbo_decoder_destroy)
    end
end

_decode_impl!(dec::TurboDecoder, Y_N, V_K) = LibAFF3CT.turbo_decode!(dec.handle, Y_N, V_K)
