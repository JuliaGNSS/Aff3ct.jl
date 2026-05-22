# Low-Density Parity-Check (LDPC) Codes

## API Reference

```@docs
LDPCMatrix
LDPCEncoder
LDPCBPDecoder
encode(::LDPCEncoder, ::AbstractVector{Int32})
decode(::LDPCBPDecoder, ::AbstractVector{Float32})
```

## Verification against upstream references

### LDPC (N=2048, K=1723) 10 Gbps Ethernet, SPA flooding, 100 iterations

Reference: `aff3ct/refs/LDPC/AWGN/BPSK/BP_FLOODING/SPA/LDPC_N2048_K1723_flooding_SPA_i100_eth_10Gbps.txt`

Configuration: 10 Gbps Ethernet LDPC code from `10GBPS-ETHERNET_1723_2048.alist`,
Belief Propagation (BP) flooding decoder using the Sum-Product Algorithm (SPA) with 100 iterations,
Binary Phase-Shift Keying (BPSK) modulation over Additive White Gaussian Noise (AWGN) channel.

| Eb/N0 (dB) | Reference BER | Reference frames |
|-------------|---------------|------------------|
| 3.00        | 1.76e-2       | 254              |
| 3.20        | 6.76e-3       | 576              |
| 3.40        | 1.75e-3       | 1 798            |

```@example ldpc
using Aff3ct, Random, Downloads

matrix_url = "https://raw.githubusercontent.com/aff3ct/configuration_files/master/dec/LDPC/10GBPS-ETHERNET_1723_2048.alist"
matrix_file = get(ENV, "AFF3CT_LDPC_MATRIX") do
    path = joinpath(tempdir(), "10GBPS-ETHERNET_1723_2048.alist")
    isfile(path) || Downloads.download(matrix_url, path)
    path
end

ebn0_to_sigma(ebn0_db, R) = Float32(1.0 / sqrt(2 * R * 10^(ebn0_db / 10)))

using CairoMakie

if isfile(matrix_file)
    H = LDPCMatrix(matrix_file)
    K, N = H.K, H.N

    function run_ldpc(H, ebn0_db, n_frames; num_iterations=100, seed=42)
        K, N = H.K, H.N
        R = K / N
        sigma = ebn0_to_sigma(ebn0_db, R)
        enc = LDPCEncoder(H)
        dec = LDPCBPDecoder(H; num_iterations=num_iterations)
        rng = Random.default_rng(); Random.seed!(rng, seed)
        total_be = 0
        for _ in 1:n_frames
            U_K = Int32.(rand(rng, Bool, K))
            X_N = encode(enc, U_K)
            bpsk = Float32[1f0 - 2f0 * x for x in X_N]
            Y_N = Float32[b + sigma * randn(rng, Float32) for b in bpsk]
            llrs = Float32[2f0 * y / sigma^2 for y in Y_N]
            V_K = decode(dec, llrs)
            total_be += count(U_K .!= V_K)
        end
        return total_be / (n_frames * K)
    end

    ebn0s = [3.0, 3.2, 3.4]
    ref_bers = [1.76e-2, 6.76e-3, 1.75e-3]
    n_frames = [254, 576, 1798]

    ber_values = Float64[]
    println("LDPC (N=$(N), K=$(K)) SPA flooding 100 ite verification:")
    for (ebn0, ref_ber, nf) in zip(ebn0s, ref_bers, n_frames)
        ber = run_ldpc(H, ebn0, nf)
        push!(ber_values, ber)
        ratio = ber > 0 ? ref_ber / ber : Inf
        println("  Eb/N0=$(ebn0)dB: BER=$(round(ber, sigdigits=3))  ref=$(ref_ber)  ratio=$(round(ratio, digits=2))x")
    end

    fig = Figure()
    ax = Axis(fig[1, 1];
        xlabel="Eb/N0 (dB)", ylabel="BER",
        yscale=log10, title="LDPC (N=2048, K=1723) SPA flooding 100 ite")
    scatterlines!(ax, ebn0s, ref_bers; label="Reference (aff3ct)", marker=:circle)
    scatterlines!(ax, ebn0s, ber_values; label="AFF3CT.jl", marker=:rect)
    axislegend(ax)
    fig
else
    println("LDPC verification skipped: set AFF3CT_LDPC_MATRIX env var to 10GBPS-ETHERNET_1723_2048.alist")
end
```
