# AFF3CT.jl

Julia bindings for the [AFF3CT](https://aff3ct.github.io/) Forward Error Correction (FEC) library.

## Supported Codes

- **Polar codes** — Encoder, Successive Cancellation (SC) decoder, SC List (SCL) decoder, frozen-bit generation via Gaussian Approximation (GA) or 5G-NR standard tables
- **Turbo codes** — Encoder/decoder with LTE interleaver and BCJR (Bahl-Cocke-Jelinek-Raviv) Soft-Input Soft-Output (SISO) component decoders
- **LDPC codes** — Low-Density Parity-Check encoder and Belief Propagation (BP) decoder using Sum-Product Algorithm (SPA) flooding

## Quick Example

```julia
using AFF3CT

# Polar encode/decode
K, N = 128, 256
fb = generate_frozen_bits_ga(K, N; design_snr=2.0)
enc = PolarEncoder(K, N, fb)
dec = PolarSCLDecoder(K, N, 8, fb)

U_K = Int32.(rand(Bool, K))
X_N = encode(enc, U_K)

# BPSK + AWGN channel
sigma = 0.5f0
Y_N = Float32[1f0 - 2f0*x for x in X_N] .+ sigma .* randn(Float32, N)
llrs = 2f0 .* Y_N ./ sigma^2

V_K = decode(dec, llrs)
```

## Verification

Each code family page includes Monte Carlo BER simulations compared against
upstream aff3ct reference curves from `aff3ct/refs/`.

## Internal Modules

```@docs
AFF3CT.LibAFF3CT
```
