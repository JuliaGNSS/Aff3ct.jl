using AFF3CT
using Test
using Random

@testset "Turbo codes" begin
    K = 40  # LTE interleaver supports specific sizes; 40 is the minimum

    # For LTE turbo: poly {013,015}, n_ff=3, tail=2*3=6 per encoder
    # N = 3*K + 4*n_ff = 3*40 + 12 = 132 (buffered turbo with tail bits)
    n_ff = 3
    N = 3 * K + 4 * n_ff

    @testset "Encode → decode (noiseless)" begin
        enc = TurboEncoder(K, N; interleaver=:LTE)
        dec = TurboDecoder(K, N; num_iterations=6, interleaver=:LTE)

        U_K = Int32.(rand(Bool, K))
        X_N = encode(enc, U_K)
        @test length(X_N) == N

        # Noiseless BPSK LLRs
        Y_N = Float32[100.0f0 * (1.0f0 - 2.0f0 * x) for x in X_N]
        V_K = decode(dec, Y_N)
        @test V_K == U_K
    end

    @testset "Encode → decode (noisy)" begin
        enc = TurboEncoder(K, N; interleaver=:LTE)
        dec = TurboDecoder(K, N; num_iterations=6, interleaver=:LTE)

        # BPSK-AWGN at Eb/N0 ≈ 2.17 dB (sigma=1.0, R≈0.303)
        # Reference BER ≈ 9.43e-3 (20 000-frame Monte Carlo)
        rng = Random.default_rng()
        Random.seed!(rng, 123)
        total_errors = 0
        n_frames = 200
        sigma = 1.0f0

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
        @test ber < 3e-2  # ~3× reference BER to account for statistical variance
    end
end
