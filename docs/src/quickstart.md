# Quick start

Given a model `model` and an initial solution `x0`, the following can be used to optimize the model using Pavito and Ipopt.
```julia
using NonconvexPavito

alg = PavitoIpoptCbcAlg()
options = PavitoIpoptCbcOptions()
result = optimize(model, alg, x0, options = options)
```
Pavito is a dependency of NonconvexPavito. Note that the integer constraints must be specified when defining variables. See the [problem definition](../core/models.md) documentation for more details.

## Construct an instance

To construct an instance of the Pavito + Ipopt + Cbc algorithm, use:
```julia
alg = PavitoIpoptCbcAlg()
```
