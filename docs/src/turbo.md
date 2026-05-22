# Turbo Codes

## API Reference

```@docs
TurboEncoder
TurboDecoder
```

## Verification against upstream references

### Turbo (K=6144, 6 iterations, LTE interleaver)

Reference: `aff3ct/refs/TURBO/AWGN/BPSK/RSC_RSC/BCJR/LTE/Turbo_N18432_K6144_BCJR_i6_p32_LTE.txt`

Configuration: LTE turbo code with generator polynomials {013, 015} in octal,
Bahl-Cocke-Jelinek-Raviv (BCJR) Soft-Input Soft-Output (SISO) component decoders,
LTE_VEC scaling factor (0.75x extrinsic information), 6 turbo iterations, BPSK-AWGN.

| Eb/N0 (dB) | Reference BER | Reference frames |
|-------------|---------------|------------------|
| 0.30        | 3.09e-2       | 824              |
| 0.40        | 9.01e-3       | 1 148            |
| 0.50        | 1.31e-3       | 2 508            |

```@example turbo
using Aff3ct, Random

ebn0_to_sigma(ebn0_db, R) = Float32(1.0 / sqrt(2 * R * 10^(ebn0_db / 10)))

function run_turbo(K, ebn0_db, n_frames; num_iterations=6, seed=123)
    n_ff = 3
    N = 3 * K + 4 * n_ff
    R = K / N
    sigma = ebn0_to_sigma(ebn0_db, R)
    enc = TurboEncoder(K, N; interleaver=:LTE)
    dec = TurboDecoder(K, N; num_iterations=num_iterations, interleaver=:LTE)
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

ebn0s = [0.3, 0.4, 0.5]
ref_bers = [3.09e-2, 9.01e-3, 1.31e-3]
n_frames = [824, 1148, 2508]

ber_values = Float64[]
println("Turbo (K=6144, N=18444, 6 ite, LTE) verification:")
for (ebn0, ref_ber, nf) in zip(ebn0s, ref_bers, n_frames)
    ber = run_turbo(6144, ebn0, nf)
    push!(ber_values, ber)
    ratio = ber > 0 ? ref_ber / ber : Inf
    println("  Eb/N0=$(ebn0)dB: BER=$(round(ber, sigdigits=3))  ref=$(ref_ber)  ratio=$(round(ratio, digits=2))x")
end

using CairoMakie

fig = Figure()
ax = Axis(fig[1, 1];
    xlabel="Eb/N0 (dB)", ylabel="BER",
    yscale=log10, title="Turbo (K=6144, 6 ite, LTE)")
scatterlines!(ax, ebn0s, ref_bers; label="Reference (aff3ct)", marker=:circle)
scatterlines!(ax, ebn0s, ber_values; label="Aff3ct.jl", marker=:rect)
axislegend(ax)
fig
```
