using Aff3ct
using Test
using Random

@testset "Feedforward Convolutional + Viterbi codes" begin
    # Galileo E1B convolutional code: poly {0o171, 0o133}, constraint length 7
    # n_ff = 6 (max poly = 0o171 → bits = 7 → n_ff = 6)
    # rate 1/2 → N = 2 * (K + n_ff)
    K = 64
    poly = [0o171, 0o133]
    n_ff = 6
    N = length(poly) * (K + n_ff)

    @testset "Encode → Viterbi decode (noiseless)" begin
        enc = ConvEncoder(K, N, poly)
        dec = ConvViterbiDecoder(K, N, poly)

        U_K = Int32.(rand(Bool, K))
        X_N = encode(enc, U_K)
        @test length(X_N) == N

        Y_N = Float32[100.0f0 * (1.0f0 - 2.0f0 * x) for x in X_N]
        V_K = decode(dec, Y_N)
        @test V_K == U_K
    end

    @testset "Encode → Viterbi decode (noisy)" begin
        enc = ConvEncoder(K, N, poly)
        dec = ConvViterbiDecoder(K, N, poly)

        rng = Random.default_rng()
        Random.seed!(rng, 123)
        total_errors = 0
        n_frames = 200
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
        # Constraint-length-7 rate-1/2 Viterbi at 3 dB Eb/N0 should be well under 1e-2
        @test ber < 1e-2
    end

    @testset "Bool convenience methods" begin
        enc = ConvEncoder(K, N, poly)
        U_K = rand(Bool, K)
        X_N = encode(enc, U_K)
        @test length(X_N) == N
    end

    @testset "Short constraint length (K=3)" begin
        # poly {015, 013}, constraint length 4 → n_ff = 3
        K2 = 64
        poly2 = [0o015, 0o013]
        n_ff2 = 3
        N2 = length(poly2) * (K2 + n_ff2)

        enc = ConvEncoder(K2, N2, poly2)
        dec = ConvViterbiDecoder(K2, N2, poly2)

        U_K = Int32.(rand(Bool, K2))
        X_N = encode(enc, U_K)
        @test length(X_N) == N2

        Y_N = Float32[100.0f0 * (1.0f0 - 2.0f0 * x) for x in X_N]
        V_K = decode(dec, Y_N)
        @test V_K == U_K
    end

    @testset "Invalid N raises" begin
        # N must equal n_poly * (K + n_ff); pass a clearly wrong N
        @test_throws ErrorException ConvEncoder(K, N + 1, poly)
    end
end
