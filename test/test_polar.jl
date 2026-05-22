using Aff3ct
using Test
using Random

@testset "Polar codes" begin
    K, N = 128, 256

    @testset "Frozen bits generation (GA)" begin
        fb = generate_frozen_bits_ga(K, N; design_snr=2.0)
        @test length(fb) == N
        @test count(fb) == N - K  # N-K frozen bits
        @test count(.!fb) == K    # K info bits
    end

    @testset "Encode → SC decode (noiseless)" begin
        fb = generate_frozen_bits_ga(K, N; design_snr=2.0)
        enc = PolarEncoder(K, N, fb)
        dec = PolarSCDecoder(K, N, fb)

        U_K = Int32.(rand(Bool, K))
        X_N = encode(enc, U_K)
        @test length(X_N) == N

        # Noiseless BPSK LLRs
        Y_N = Float32[100.0f0 * (1.0f0 - 2.0f0 * x) for x in X_N]
        V_K = decode(dec, Y_N)
        @test V_K == U_K
    end

    @testset "Encode → SCL decode (noisy)" begin
        fb = generate_frozen_bits_ga(K, N; design_snr=2.0)
        enc = PolarEncoder(K, N, fb)
        dec = PolarSCLDecoder(K, N, 8, fb)

        # BPSK-AWGN at Eb/N0 ≈ 1.94 dB (sigma=0.8, R=0.5)
        # Reference BER ≈ 2.66e-3 (20 000-frame Monte Carlo)
        rng = Random.default_rng()
        Random.seed!(rng, 42)
        total_errors = 0
        n_frames = 200
        sigma = 0.8f0

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
        @test ber < 8e-3  # ~3× reference BER to account for statistical variance
    end

    @testset "Bool convenience methods" begin
        fb = generate_frozen_bits_ga(K, N; design_snr=2.0)
        enc = PolarEncoder(K, N, fb)
        U_K = rand(Bool, K)
        X_N = encode(enc, U_K)
        @test length(X_N) == N
    end
end
