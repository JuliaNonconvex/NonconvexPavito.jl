# Options

The options keyword argument to the `optimize` function shown above must be an instance of `PavitoIpoptCbcOptions` struct when the algorithm is a `PavitoIpoptCbcAlg`. To specify options, use keyword arguments in the constructor of `JuniperIpoptOptions` or `PavitoIpoptCbcOptions`, e.g:
```julia
options = PavitoIpoptCbcOptions(first_order = false, subsolver_options = IpoptOptions(), timeout = 120.0)
```
There are 2 important and special options you can pass to the optimizer:
- `first_order`: `true` by default. When `first_order` is `true`, the first order Ipopt algorithm will be used. And when it is `false`, the second order Ipopt algorithm will be used.
- `subsolver_options`: an instance of `IpoptOptions` to be used in the Ipopt sub-solver.

The mixed integer sub-solver of Pavito is always [Cbc.jl](https://github.com/jump-dev/Cbc.jl). `NonconvexPavito` re-exports `IpoptAlg` and `IpoptOptions` from `NonconvexIpopt`, which can be used directly, e.g.:
```julia
using NonconvexPavito

alg = IpoptAlg()
options = IpoptOptions(first_order = false, tol = 1e-4)
result = optimize(model, alg, x0, options = options)
```

All the other options to Pavito can be found in the [Pavito documentation](https://github.com/jump-dev/Pavito.jl#pavito-solver-options).
