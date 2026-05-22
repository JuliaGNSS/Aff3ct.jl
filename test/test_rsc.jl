using Aff3ct
using Test
using Random

@testset "RSC + Viterbi codes" begin
    K = 128
    # poly {05,07} → constraint length 3, n_ff=2
    # N = 2*(K + n_ff) = 2*(128+2) = 260
    n_ff = 2
    N = 2 * (K + n_ff)

    @testset "Encode → Viterbi decode (noiseless)" begin
        enc = RSCEncoder(K, N)
        dec = ViterbiDecoder(K, N)

        U_K = Int32.(rand(Bool, K))
        X_N = encode(enc, U_K)
        @test length(X_N) == N

        # Noiseless BPSK LLRs
        Y_N = Float32[100.0f0 * (1.0f0 - 2.0f0 * x) for x in X_N]
        V_K = decode(dec, Y_N)
        @test V_K == U_K
    end

    @testset "Encode → Viterbi decode (noisy)" begin
        enc = RSCEncoder(K, N)
        dec = ViterbiDecoder(K, N)

        # BPSK-AWGN at Eb/N0 ≈ 3.0 dB (sigma derived from R ≈ 0.49)
        rng = Random.default_rng()
        Random.seed!(rng, 123)
        total_errors = 0
        n_frames = 500
        R = K / N
        ebn0_db = 3.0
        sigma = Float32(1.0 / sqrt(2 * R * 10^(ebn0_db / 10)))

        for _ in 1:n_frames
            U_K = Int32.(rand(rng, Bool, K))
            X_N = encode(enc, U_K)
            bpsk = Float32[1.0f0 - 2.0f0 * x for x in X_N]
            Y_N = Float32[b + sigma * randn(rng, Float32) for b in bpsk]
            llrs = Float32[2.0f0 * y / sigma^2 for y in Y_N]
            V_K = decode(dec, llrs)
            total_errors += count(U_K .!= V_K)
        end

        ber = total_errors / (n_frames * K)
        # Rate-1/2 conv code with Viterbi at 3 dB should have BER < ~1e-2
        @test ber < 3e-2
    end

    @testset "Bool convenience methods" begin
        enc = RSCEncoder(K, N)
        U_K = rand(Bool, K)
        X_N = encode(enc, U_K)
        @test length(X_N) == N
    end

    @testset "Custom polynomials" begin
        # LTE polynomials {013, 015}, n_ff=3, N = 2*(128+3) = 262
        K2 = 128
        n_ff2 = 3
        N2 = 2 * (K2 + n_ff2)
        enc = RSCEncoder(K2, N2; poly=[013, 015])
        dec = ViterbiDecoder(K2, N2; poly=[013, 015])

        U_K = Int32.(rand(Bool, K2))
        X_N = encode(enc, U_K)
        @test length(X_N) == N2

        Y_N = Float32[100.0f0 * (1.0f0 - 2.0f0 * x) for x in X_N]
        V_K = decode(dec, Y_N)
        @test V_K == U_K
    end
end
