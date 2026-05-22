# Convolutional Codes (RSC)

## API Reference

```@docs
RSCEncoder
ViterbiDecoder
```

## Verification against upstream references

### RSC + Viterbi (K=128, poly {05, 07}, rate 1/2)

Configuration: Rate-1/2 RSC code with generator polynomials {05, 07} in octal
(constraint length 3, 2 memory elements), Viterbi (SIHO) decoder with trellis
termination (buffered), BPSK-AWGN.

```@example rsc
using Aff3ct, Random

ebn0_to_sigma(ebn0_db, R) = Float32(1.0 / sqrt(2 * R * 10^(ebn0_db / 10)))

function run_rsc(K, ebn0_db, n_frames; seed=123)
    n_ff = 2  # constraint length 3 → 2 memory elements
    N = 2 * (K + n_ff)
    R = K / N
    sigma = ebn0_to_sigma(ebn0_db, R)
    enc = RSCEncoder(K, N)
    dec = ViterbiDecoder(K, N)
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

ebn0s = [1.0, 2.0, 3.0, 4.0, 5.0]
n_frames = 10_000

ber_values = Float64[]
println("RSC + Viterbi (K=128, poly {05,07}, rate ≈ 1/2) BER:")
for ebn0 in ebn0s
    ber = run_rsc(128, ebn0, n_frames)
    push!(ber_values, ber)
    println("  Eb/N0=$(ebn0)dB: BER=$(round(ber, sigdigits=3))")
end

using CairoMakie

fig = Figure()
ax = Axis(fig[1, 1];
    xlabel="Eb/N0 (dB)", ylabel="BER",
    yscale=log10, title="RSC + Viterbi (K=128, rate ≈ 1/2)")
scatterlines!(ax, ebn0s, ber_values; label="Aff3ct.jl", marker=:circle)
axislegend(ax)
fig
```
