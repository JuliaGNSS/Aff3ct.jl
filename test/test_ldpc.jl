using AFF3CT
using Test
using Random

@testset "LDPC codes" begin
    matrix_file = joinpath(@__DIR__, "CCSDS_64_128.alist")

    H = LDPCMatrix(matrix_file)
    K, N = H.K, H.N

    @testset "Matrix loading" begin
        @test H.M > 0
        @test H.N > H.M
        @test H.K == H.N - H.M
        @test length(H.info_bits_pos) == K
    end

    @testset "Encode → BP decode (noiseless)" begin
        enc = LDPCEncoder(H)
        dec = LDPCBPDecoder(H; num_iterations=50)

        U_K = Int32.(rand(Bool, K))
        X_N = encode(enc, U_K)
        @test length(X_N) == N

        Y_N = Float32[100.0f0 * (1.0f0 - 2.0f0 * x) for x in X_N]
        V_K = decode(dec, Y_N)
        @test V_K == U_K
    end

    @testset "Encode → BP decode (noisy)" begin
        enc = LDPCEncoder(H)
        dec = LDPCBPDecoder(H; num_iterations=50)

        # BPSK-AWGN at Eb/N0 = 3.0 dB (R=0.5)
        # Reference BER ≈ 6.6e-3 (10 000-frame Monte Carlo)
        rng = Random.default_rng()
        Random.seed!(rng, 123)
        total_errors = 0
        n_frames = 500
        R = K / N
        sigma = Float32(1.0 / sqrt(2 * R * 10^(3.0 / 10)))

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
        @test ber < 2e-2  # ~3× reference BER to account for statistical variance
    end
end
