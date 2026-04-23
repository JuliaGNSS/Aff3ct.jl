# ── Abstract types and shared encode/decode logic ───────────────────

abstract type AbstractEncoder end
abstract type AbstractDecoder end

# Each concrete encoder/decoder type must:
#   - be a mutable struct with fields `handle::Ptr{Cvoid}`, `K::Int`, `N::Int`
#   - declare `_encode_impl!` / `_decode_impl!` pointing at the ccall wrapper

function encode!(X_N::Vector{Int32}, enc::AbstractEncoder, U_K::AbstractVector{Int32})
    length(U_K) == enc.K || throw(DimensionMismatch("Expected $(enc.K) info bits, got $(length(U_K))"))
    length(X_N) == enc.N || throw(DimensionMismatch("Expected output buffer of length $(enc.N), got $(length(X_N))"))
    _encode_impl!(enc, U_K, X_N)
    return X_N
end

function encode(enc::AbstractEncoder, U_K::AbstractVector{Int32})
    length(U_K) == enc.K || throw(DimensionMismatch("Expected $(enc.K) info bits, got $(length(U_K))"))
    X_N = Vector{Int32}(undef, enc.N)
    _encode_impl!(enc, U_K, X_N)
    return X_N
end

encode(enc::AbstractEncoder, U_K::AbstractVector{Bool}) = encode(enc, Int32.(U_K))
encode(enc::AbstractEncoder, U_K::AbstractVector{<:Integer}) = encode(enc, Int32.(U_K))

function decode!(V_K::Vector{Int32}, dec::AbstractDecoder, Y_N::AbstractVector{Float32})
    length(Y_N) == dec.N || throw(DimensionMismatch("Expected $(dec.N) LLRs, got $(length(Y_N))"))
    length(V_K) == dec.K || throw(DimensionMismatch("Expected output buffer of length $(dec.K), got $(length(V_K))"))
    _decode_impl!(dec, Y_N, V_K)
    return V_K
end

function decode(dec::AbstractDecoder, Y_N::AbstractVector{Float32})
    length(Y_N) == dec.N || throw(DimensionMismatch("Expected $(dec.N) LLRs, got $(length(Y_N))"))
    V_K = Vector{Int32}(undef, dec.K)
    _decode_impl!(dec, Y_N, V_K)
    return V_K
end

decode(dec::AbstractDecoder, Y_N::AbstractVector{<:AbstractFloat}) = decode(dec, Float32.(Y_N))

Base.show(io::IO, enc::AbstractEncoder) = print(io, nameof(typeof(enc)), "(K=", enc.K, ", N=", enc.N, ")")
Base.show(io::IO, dec::AbstractDecoder) = print(io, nameof(typeof(dec)), "(K=", dec.K, ", N=", dec.N, ")")
