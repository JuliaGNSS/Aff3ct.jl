# ── Sparse matrix loading ────────────────────────────────────────────

"""
    LDPCMatrix

Loaded LDPC parity-check matrix (H) with associated info bit positions.
"""
mutable struct LDPCMatrix
    handle::Ptr{Cvoid}
    M::Int  # rows (parity checks)
    N::Int  # columns (codeword length)
    K::Int  # info bits = N - M
    info_bits_pos::Vector{UInt32}

    function LDPCMatrix(filepath::String)
        isfile(filepath) || throw(SystemError("LDPC matrix file not found: $filepath", 2))

        # First pass: load to get dimensions and true K (= rank-based info bits count)
        empty_ibp = Vector{UInt32}(undef, 0)
        h_probe, _, N = LibAFF3CT.sparse_matrix_load(filepath, empty_ibp)
        K = LibAFF3CT.sparse_matrix_info_bits_count(h_probe)
        M = N - K
        LibAFF3CT.sparse_matrix_destroy(h_probe)

        # Second pass: with info_bits_pos buffer of correct size
        ibp = Vector{UInt32}(undef, K)
        handle, _, _ = LibAFF3CT.sparse_matrix_load(filepath, ibp)

        LibAFF3CT.attach_finalizer!(new(handle, M, N, K, ibp),
                                    LibAFF3CT.sparse_matrix_destroy)
    end
end

Base.show(io::IO, H::LDPCMatrix) =
    print(io, "LDPCMatrix(M=", H.M, ", N=", H.N, ", K=", H.K, ")")

# ── LDPC Encoder ─────────────────────────────────────────────────────

"""
    LDPCEncoder(H::LDPCMatrix)

LDPC encoder constructed from parity-check matrix `H`.
Internally computes generator matrix G via LU decomposition.
"""
mutable struct LDPCEncoder <: AbstractEncoder
    handle::Ptr{Cvoid}
    K::Int
    N::Int

    function LDPCEncoder(H::LDPCMatrix)
        handle = LibAFF3CT.ldpc_encoder_create(H.K, H.N, H.handle)
        LibAFF3CT.attach_finalizer!(new(handle, H.K, H.N),
                                    LibAFF3CT.ldpc_encoder_destroy)
    end
end

_encode_impl!(enc::LDPCEncoder, U_K, X_N) = LibAFF3CT.ldpc_encode!(enc.handle, U_K, X_N)

# ── LDPC BP Decoder ──────────────────────────────────────────────────

"""
    LDPCBPDecoder(H::LDPCMatrix; num_iterations=50)

Belief Propagation (flooding SPA) decoder for LDPC codes.
`num_iterations` is the maximum number of BP iterations.
"""
mutable struct LDPCBPDecoder <: AbstractDecoder
    handle::Ptr{Cvoid}
    K::Int
    N::Int

    function LDPCBPDecoder(H::LDPCMatrix; num_iterations::Integer=50)
        handle = LibAFF3CT.ldpc_bp_decoder_create(H.K, H.N, num_iterations, H.handle, H.info_bits_pos)
        LibAFF3CT.attach_finalizer!(new(handle, H.K, H.N),
                                    LibAFF3CT.ldpc_bp_decoder_destroy)
    end
end

_decode_impl!(dec::LDPCBPDecoder, Y_N, V_K) = LibAFF3CT.ldpc_bp_decode!(dec.handle, Y_N, V_K)
