## Pavito + Ipopt + Cbc

### Quick start

Given a model `model` and an initial solution `x0`, the following can be used to optimize the model using Pavito and Ipopt.
```julia
using NonconvexPavito

alg = PavitoIpoptCbcAlg()
options = PavitoIpoptCbcOptions()
result = optimize(model, alg, x0, options = options)
```
Pavito is a dependency of NonconvexPavito. Note that the integer constraints must be specified when defining variables. See the [problem definition](../core/models.md) documentation for more details.

### Construct an instance

To construct an instance of the Pavito + Ipopt + Cbc algorithm, use:
```julia
alg = PavitoIpoptCbcAlg()
```

### Options

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

### Results

The result of `optimize` is an `AbstractResult` with the following fields:
- `minimizer`: the solution found.
- `minimum`: the objective value at the solution found.
- `status`: a tuple of the MOI termination and primal statuses, e.g. `(MOI.OPTIMAL, MOI.FEASIBLE_POINT)`.
- `fcalls`: the number of objective function calls.

For example:
```julia
r = optimize(model, alg, x0, options = options)
r.minimizer
r.minimum
r.status
r.fcalls
```
