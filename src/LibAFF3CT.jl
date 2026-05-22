"""
    LibAFF3CT

Raw `ccall` wrappers around the `libaff3ct_jl` C API.
These are thin, unsafe wrappers — prefer the high-level API in `AFF3CT`.
"""
module LibAFF3CT

# Use JLL when available, otherwise fall back to local build via env var
if get(ENV, "AFF3CT_JL_LOCAL_LIB", "") != ""
    const libaff3ct_jl = ENV["AFF3CT_JL_LOCAL_LIB"]
else
    using aff3ct_jll: libaff3ct_jl
end

# ── Version / error ──────────────────────────────────────────────────

function version()
    ptr = ccall((:aff3ct_jl_version, libaff3ct_jl), Cstring, ())
    return unsafe_string(ptr)
end

function last_error()
    ptr = ccall((:aff3ct_jl_last_error, libaff3ct_jl), Cstring, ())
    ptr == C_NULL && return nothing
    return unsafe_string(ptr)
end

function check_error()
    err = last_error()
    err !== nothing && error("aff3ct error: $err")
end

function check_handle(ptr::Ptr{Cvoid}, what::String)
    ptr == C_NULL && error("Failed to create $what: $(something(last_error(), "unknown error"))")
    return ptr
end

# Attach a finalizer that calls `destroy_fn(obj.handle)` exactly once and nulls the handle.
function attach_finalizer!(obj, destroy_fn)
    finalizer(obj) do x
        x.handle == C_NULL && return
        destroy_fn(x.handle)
        x.handle = C_NULL
    end
    return obj
end

# ── Frozen bits generators ───────────────────────────────────────────

function frozenbits_gen_ga_create(K::Integer, N::Integer, design_snr::Real)
    h = ccall((:aff3ct_frozenbits_gen_ga_create, libaff3ct_jl),
              Ptr{Cvoid}, (Cint, Cint, Cfloat), K, N, design_snr)
    return check_handle(h, "GA frozen bits generator")
end

function frozenbits_gen_5g_create(K::Integer, N::Integer)
    h = ccall((:aff3ct_frozenbits_gen_5g_create, libaff3ct_jl),
              Ptr{Cvoid}, (Cint, Cint), K, N)
    return check_handle(h, "5G frozen bits generator")
end

function frozenbits_gen_generate!(gen::Ptr{Cvoid}, frozen_bits::Vector{Cint})
    ret = ccall((:aff3ct_frozenbits_gen_generate, libaff3ct_jl),
                Cint, (Ptr{Cvoid}, Ptr{Cint}), gen, frozen_bits)
    ret != 0 && check_error()
    return frozen_bits
end

function frozenbits_gen_destroy(gen::Ptr{Cvoid})
    ccall((:aff3ct_frozenbits_gen_destroy, libaff3ct_jl), Cvoid, (Ptr{Cvoid},), gen)
end

# ── Polar encoder ────────────────────────────────────────────────────

function polar_encoder_create(K::Integer, N::Integer, frozen_bits::Vector{Cint})
    h = ccall((:aff3ct_polar_encoder_create, libaff3ct_jl),
              Ptr{Cvoid}, (Cint, Cint, Ptr{Cint}), K, N, frozen_bits)
    return check_handle(h, "Polar encoder")
end

function polar_encode!(enc::Ptr{Cvoid}, U_K::Vector{Cint}, X_N::Vector{Cint})
    ret = ccall((:aff3ct_polar_encode, libaff3ct_jl),
                Cint, (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cint}), enc, U_K, X_N)
    ret != 0 && check_error()
    return X_N
end

function polar_encoder_destroy(enc::Ptr{Cvoid})
    ccall((:aff3ct_polar_encoder_destroy, libaff3ct_jl), Cvoid, (Ptr{Cvoid},), enc)
end

# ── Polar SC decoder ─────────────────────────────────────────────────

function polar_sc_decoder_create(K::Integer, N::Integer, frozen_bits::Vector{Cint})
    h = ccall((:aff3ct_polar_sc_decoder_create, libaff3ct_jl),
              Ptr{Cvoid}, (Cint, Cint, Ptr{Cint}), K, N, frozen_bits)
    return check_handle(h, "Polar SC decoder")
end

function polar_sc_decode!(dec::Ptr{Cvoid}, Y_N::Vector{Cfloat}, V_K::Vector{Cint})
    ret = ccall((:aff3ct_polar_sc_decode, libaff3ct_jl),
                Cint, (Ptr{Cvoid}, Ptr{Cfloat}, Ptr{Cint}), dec, Y_N, V_K)
    ret < 0 && check_error()
    return V_K
end

function polar_sc_decoder_destroy(dec::Ptr{Cvoid})
    ccall((:aff3ct_polar_sc_decoder_destroy, libaff3ct_jl), Cvoid, (Ptr{Cvoid},), dec)
end

# ── Polar SCL decoder ────────────────────────────────────────────────

function polar_scl_decoder_create(K::Integer, N::Integer, L::Integer, frozen_bits::Vector{Cint})
    h = ccall((:aff3ct_polar_scl_decoder_create, libaff3ct_jl),
              Ptr{Cvoid}, (Cint, Cint, Cint, Ptr{Cint}), K, N, L, frozen_bits)
    return check_handle(h, "Polar SCL decoder")
end

function polar_scl_decode!(dec::Ptr{Cvoid}, Y_N::Vector{Cfloat}, V_K::Vector{Cint})
    ret = ccall((:aff3ct_polar_scl_decode, libaff3ct_jl),
                Cint, (Ptr{Cvoid}, Ptr{Cfloat}, Ptr{Cint}), dec, Y_N, V_K)
    ret < 0 && check_error()
    return V_K
end

function polar_scl_decoder_destroy(dec::Ptr{Cvoid})
    ccall((:aff3ct_polar_scl_decoder_destroy, libaff3ct_jl), Cvoid, (Ptr{Cvoid},), dec)
end

# ── Sparse matrix I/O ────────────────────────────────────────────────

function sparse_matrix_load(filepath::String, info_bits_pos::Vector{Cuint})
    out_M = Ref{Cint}(0)
    out_N = Ref{Cint}(0)
    h = ccall((:aff3ct_sparse_matrix_load, libaff3ct_jl),
              Ptr{Cvoid}, (Cstring, Ptr{Cint}, Ptr{Cint}, Ptr{Cuint}, Cint),
              filepath, out_M, out_N, info_bits_pos, length(info_bits_pos))
    check_handle(h, "sparse matrix from '$filepath'")
    return h, Int(out_M[]), Int(out_N[])
end

function sparse_matrix_info_bits_count(mat::Ptr{Cvoid})
    Int(ccall((:aff3ct_sparse_matrix_info_bits_count, libaff3ct_jl), Cint, (Ptr{Cvoid},), mat))
end

function sparse_matrix_destroy(mat::Ptr{Cvoid})
    ccall((:aff3ct_sparse_matrix_destroy, libaff3ct_jl), Cvoid, (Ptr{Cvoid},), mat)
end

# ── LDPC encoder ─────────────────────────────────────────────────────

function ldpc_encoder_create(K::Integer, N::Integer, H::Ptr{Cvoid})
    h = ccall((:aff3ct_ldpc_encoder_create, libaff3ct_jl),
              Ptr{Cvoid}, (Cint, Cint, Ptr{Cvoid}), K, N, H)
    return check_handle(h, "LDPC encoder")
end

function ldpc_encode!(enc::Ptr{Cvoid}, U_K::Vector{Cint}, X_N::Vector{Cint})
    ret = ccall((:aff3ct_ldpc_encode, libaff3ct_jl),
                Cint, (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cint}), enc, U_K, X_N)
    ret != 0 && check_error()
    return X_N
end

function ldpc_encoder_destroy(enc::Ptr{Cvoid})
    ccall((:aff3ct_ldpc_encoder_destroy, libaff3ct_jl), Cvoid, (Ptr{Cvoid},), enc)
end

# ── LDPC BP decoder ──────────────────────────────────────────────────

function ldpc_bp_decoder_create(K::Integer, N::Integer, num_iterations::Integer,
                                 H::Ptr{Cvoid}, info_bits_pos::Vector{Cuint})
    h = ccall((:aff3ct_ldpc_bp_decoder_create, libaff3ct_jl),
              Ptr{Cvoid}, (Cint, Cint, Cint, Ptr{Cvoid}, Ptr{Cuint}),
              K, N, num_iterations, H, info_bits_pos)
    return check_handle(h, "LDPC BP decoder")
end

function ldpc_bp_decode!(dec::Ptr{Cvoid}, Y_N::Vector{Cfloat}, V_K::Vector{Cint})
    ret = ccall((:aff3ct_ldpc_bp_decode, libaff3ct_jl),
                Cint, (Ptr{Cvoid}, Ptr{Cfloat}, Ptr{Cint}), dec, Y_N, V_K)
    ret < 0 && check_error()
    return V_K
end

function ldpc_bp_decoder_destroy(dec::Ptr{Cvoid})
    ccall((:aff3ct_ldpc_bp_decoder_destroy, libaff3ct_jl), Cvoid, (Ptr{Cvoid},), dec)
end

# ── RSC encoder ──────────────────────────────────────────────────────

function rsc_encoder_create(K::Integer, N::Integer,
                             poly::Union{Nothing,Vector{Cint}}=nothing)
    poly_arg = poly === nothing ? C_NULL : poly
    poly_len = poly === nothing ? Cint(0) : Cint(length(poly))
    h = ccall((:aff3ct_rsc_encoder_create, libaff3ct_jl),
              Ptr{Cvoid}, (Cint, Cint, Ptr{Cint}, Cint),
              K, N, poly_arg, poly_len)
    return check_handle(h, "RSC encoder")
end

function rsc_encode!(enc::Ptr{Cvoid}, U_K::Vector{Cint}, X_N::Vector{Cint})
    ret = ccall((:aff3ct_rsc_encode, libaff3ct_jl),
                Cint, (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cint}), enc, U_K, X_N)
    ret != 0 && check_error()
    return X_N
end

function rsc_encoder_destroy(enc::Ptr{Cvoid})
    ccall((:aff3ct_rsc_encoder_destroy, libaff3ct_jl), Cvoid, (Ptr{Cvoid},), enc)
end

# ── Viterbi decoder ──────────────────────────────────────────────────

function viterbi_decoder_create(K::Integer, N::Integer,
                                 poly::Union{Nothing,Vector{Cint}}=nothing)
    poly_arg = poly === nothing ? C_NULL : poly
    poly_len = poly === nothing ? Cint(0) : Cint(length(poly))
    h = ccall((:aff3ct_viterbi_decoder_create, libaff3ct_jl),
              Ptr{Cvoid}, (Cint, Cint, Ptr{Cint}, Cint),
              K, N, poly_arg, poly_len)
    return check_handle(h, "Viterbi decoder")
end

function viterbi_decode!(dec::Ptr{Cvoid}, Y_N::Vector{Cfloat}, V_K::Vector{Cint})
    ret = ccall((:aff3ct_viterbi_decode, libaff3ct_jl),
                Cint, (Ptr{Cvoid}, Ptr{Cfloat}, Ptr{Cint}), dec, Y_N, V_K)
    ret < 0 && check_error()
    return V_K
end

function viterbi_decoder_destroy(dec::Ptr{Cvoid})
    ccall((:aff3ct_viterbi_decoder_destroy, libaff3ct_jl), Cvoid, (Ptr{Cvoid},), dec)
end

# ── Feedforward convolutional encoder ────────────────────────────────

function conv_encoder_create(K::Integer, N::Integer, poly::Vector{Cint})
    h = ccall((:aff3ct_conv_encoder_create, libaff3ct_jl),
              Ptr{Cvoid}, (Cint, Cint, Ptr{Cint}, Cint),
              K, N, poly, length(poly))
    return check_handle(h, "feedforward conv encoder")
end

function conv_encode!(enc::Ptr{Cvoid}, U_K::Vector{Cint}, X_N::Vector{Cint})
    ret = ccall((:aff3ct_conv_encode, libaff3ct_jl),
                Cint, (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cint}), enc, U_K, X_N)
    ret != 0 && check_error()
    return X_N
end

function conv_encoder_destroy(enc::Ptr{Cvoid})
    ccall((:aff3ct_conv_encoder_destroy, libaff3ct_jl), Cvoid, (Ptr{Cvoid},), enc)
end

# ── Feedforward convolutional Viterbi decoder ────────────────────────

function conv_viterbi_decoder_create(K::Integer, N::Integer, poly::Vector{Cint})
    h = ccall((:aff3ct_conv_viterbi_decoder_create, libaff3ct_jl),
              Ptr{Cvoid}, (Cint, Cint, Ptr{Cint}, Cint),
              K, N, poly, length(poly))
    return check_handle(h, "feedforward conv Viterbi decoder")
end

function conv_viterbi_decode!(dec::Ptr{Cvoid}, Y_N::Vector{Cfloat}, V_K::Vector{Cint})
    ret = ccall((:aff3ct_conv_viterbi_decode, libaff3ct_jl),
                Cint, (Ptr{Cvoid}, Ptr{Cfloat}, Ptr{Cint}), dec, Y_N, V_K)
    ret < 0 && check_error()
    return V_K
end

function conv_viterbi_decoder_destroy(dec::Ptr{Cvoid})
    ccall((:aff3ct_conv_viterbi_decoder_destroy, libaff3ct_jl), Cvoid, (Ptr{Cvoid},), dec)
end

# ── Turbo encoder ────────────────────────────────────────────────────

function turbo_encoder_create(K::Integer, N::Integer, interleaver_type::String,
                               poly::Union{Nothing,Vector{Cint}}=nothing)
    poly_arg = poly === nothing ? C_NULL : poly
    poly_len = poly === nothing ? Cint(0) : Cint(length(poly))
    h = ccall((:aff3ct_turbo_encoder_create, libaff3ct_jl),
              Ptr{Cvoid}, (Cint, Cint, Cstring, Ptr{Cint}, Cint),
              K, N, interleaver_type, poly_arg, poly_len)
    return check_handle(h, "Turbo encoder")
end

function turbo_encode!(enc::Ptr{Cvoid}, U_K::Vector{Cint}, X_N::Vector{Cint})
    ret = ccall((:aff3ct_turbo_encode, libaff3ct_jl),
                Cint, (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cint}), enc, U_K, X_N)
    ret != 0 && check_error()
    return X_N
end

function turbo_encoder_destroy(enc::Ptr{Cvoid})
    ccall((:aff3ct_turbo_encoder_destroy, libaff3ct_jl), Cvoid, (Ptr{Cvoid},), enc)
end

# ── Turbo decoder ────────────────────────────────────────────────────

function turbo_decoder_create(K::Integer, N::Integer, num_iterations::Integer,
                               interleaver_type::String,
                               poly::Union{Nothing,Vector{Cint}}=nothing;
                               buffered_encoding::Bool=true)
    poly_arg = poly === nothing ? C_NULL : poly
    poly_len = poly === nothing ? Cint(0) : Cint(length(poly))
    h = ccall((:aff3ct_turbo_decoder_create, libaff3ct_jl),
              Ptr{Cvoid}, (Cint, Cint, Cint, Cstring, Ptr{Cint}, Cint, Cint),
              K, N, num_iterations, interleaver_type, poly_arg, poly_len, buffered_encoding ? 1 : 0)
    return check_handle(h, "Turbo decoder")
end

function turbo_decode!(dec::Ptr{Cvoid}, Y_N::Vector{Cfloat}, V_K::Vector{Cint})
    ret = ccall((:aff3ct_turbo_decode, libaff3ct_jl),
                Cint, (Ptr{Cvoid}, Ptr{Cfloat}, Ptr{Cint}), dec, Y_N, V_K)
    ret < 0 && check_error()
    return V_K
end

function turbo_decoder_destroy(dec::Ptr{Cvoid})
    ccall((:aff3ct_turbo_decoder_destroy, libaff3ct_jl), Cvoid, (Ptr{Cvoid},), dec)
end

end # module LibAFF3CT
