# NonconvexPavito

## Description

[Pavito.jl](https://github.com/jump-dev/Pavito.jl) implements the sequential polyhedral outer-approximation algorithm for mixed integer nonlinear programming, with [Ipopt.jl](https://github.com/jump-dev/Ipopt.jl) as the continuous NLP sub-solver and [Cbc.jl](https://github.com/jump-dev/Cbc.jl) as the mixed integer sub-solver. `NonconvexPavito.jl` allows the use of `Pavito.jl` through the `PavitoIpoptCbcAlg` algorithm struct.

See [Quick start](quickstart.md) for the first steps, [Options](options.md) for the algorithm options, [Solver capabilities](capabilities.md) for the model features supported by `PavitoIpoptCbcAlg`, [Result](result.md) for the fields of the returned result and [Docstrings](docstrings.md) for the full API reference.
