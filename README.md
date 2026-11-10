<p align="center">
  <img src="assets/logo.png" width="400" alt="NonconvexPavito.jl logo">
</p>

[![Documentation (stable)](https://img.shields.io/badge/docs-stable-blue.svg)](https://julianonconvex.github.io/NonconvexPavito.jl/stable)
[![Documentation (dev)](https://img.shields.io/badge/docs-dev-blue.svg)](https://julianonconvex.github.io/NonconvexPavito.jl/dev)
[![Build Status](https://github.com/JuliaNonconvex/NonconvexPavito.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/JuliaNonconvex/NonconvexPavito.jl/actions)
[![Coverage](https://codecov.io/gh/JuliaNonconvex/NonconvexPavito.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaNonconvex/NonconvexPavito.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-Blue-4473c9.svg)](https://github.com/invenia/BlueStyle)
[![JET](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a)](https://github.com/aviatesk/JET.jl)

# NonconvexPavito.jl

Mixed-integer nonlinear programming with Pavito.jl

Outer approximation MINLP with Ipopt and Cbc as the sub-solvers.

NonconvexPavito.jl is part of the [JuliaNonconvex](https://github.com/JuliaNonconvex) ecosystem built on [NonconvexCore.jl](https://github.com/JuliaNonconvex/NonconvexCore.jl).

## Quick start

```julia
using NonconvexPavito

alg = PavitoIpoptCbcAlg()
options = PavitoIpoptCbcOptions()
result = optimize(model, alg, x0, options = options)
```

## Documentation

The full documentation is available at [https://julianonconvex.github.io/NonconvexPavito.jl/stable](https://julianonconvex.github.io/NonconvexPavito.jl/stable) (stable) and [https://julianonconvex.github.io/NonconvexPavito.jl/dev](https://julianonconvex.github.io/NonconvexPavito.jl/dev) (development).

## Installation

```julia
using Pkg
Pkg.add("NonconvexPavito")
```
