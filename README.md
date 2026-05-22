# AFF3CT.jl

[![Build Status](https://github.com/JuliaGNSS/AFF3CT.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaGNSS/AFF3CT.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaGNSS.github.io/AFF3CT.jl/dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Julia bindings for [AFF3CT](https://aff3ct.github.io/), a fast forward-error-correction toolbox. Wraps the C++ implementations of Polar, LDPC, Turbo, RSC, and feedforward convolutional codes behind a Julia-native API.

## Installation

```julia
using Pkg
Pkg.add("AFF3CT")
```

Binaries are provided via `aff3ct_jll` — no separate C/C++ build is required.

## Quick example

```julia
using AFF3CT

# Polar (N=128, K=96) with Gaussian-Approximation frozen bits
fb  = generate_frozen_bits_ga(96, 128; design_snr=2.0)
enc = PolarEncoder(96, 128, fb)
dec = PolarSCDecoder(96, 128, fb)

U_K = rand(Bool, 96)
X_N = encode(enc, U_K)

# Noiseless BPSK LLRs
Y_N = Float32[100f0 * (1f0 - 2f0 * x) for x in X_N]
V_K = decode(dec, Y_N)
@assert V_K == U_K
```

In-place variants `encode!` / `decode!` avoid per-call allocation and are recommended for tight Monte-Carlo loops.

## Supported codes

| Family                  | Encoders                | Decoders                                    |
|-------------------------|-------------------------|---------------------------------------------|
| Polar                   | `PolarEncoder`          | `PolarSCDecoder`, `PolarSCLDecoder`         |
| LDPC                    | `LDPCEncoder`           | `LDPCBPDecoder`                             |
| Turbo                   | `TurboEncoder`          | `TurboDecoder`                              |
| RSC                     | `RSCEncoder`            | `ViterbiDecoder`                            |
| Feedforward conv        | `ConvEncoder`           | `ConvViterbiDecoder`                        |

See the [documentation](https://JuliaGNSS.github.io/AFF3CT.jl/dev) for BER curves and per-codec parameter details.

## License

MIT. AFF3CT itself is also MIT-licensed — see [aff3ct/aff3ct](https://github.com/aff3ct/aff3ct).
