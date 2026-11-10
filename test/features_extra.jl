# Additional feature tests for NonconvexPavito (src/NonconvexPavito.jl)
# targeting the exported-surface gaps not covered by the main suite: the
# PavitoIpoptCbcOptions fields and kwargs passthrough, the positional
# NamedTuple constructor, the result fields (status/termination), the
# no-explicit-start-point path, the full capability declaration and the
# start-vector error path.

@testitem "PavitoIpoptCbcOptions fields" begin
    using NonconvexPavito, Test

    @testset "defaults" begin
        o = PavitoIpoptCbcOptions()
        @test o.first_order === true
        @test o.nt == NamedTuple()
        # The default subsolver is first order.
        @test o.subsolver_options.nt.hessian_approximation == "limited-memory"
    end

    @testset "first_order" begin
        o = PavitoIpoptCbcOptions(first_order=false)
        @test o.first_order === false
        @test o.subsolver_options.nt.hessian_approximation == "exact"
        # An explicit first_order=false wins over a conflicting subsolver.
        o = PavitoIpoptCbcOptions(
            first_order=false, subsolver_options=IpoptOptions(first_order=true)
        )
        @test o.first_order === false
        @test o.subsolver_options.nt.hessian_approximation == "limited-memory"
        # Without an explicit first_order, derive it from the subsolver's
        # hessian_approximation.
        @test PavitoIpoptCbcOptions(
            subsolver_options=IpoptOptions(hessian_approximation="exact")
        ).first_order === false
        @test PavitoIpoptCbcOptions(
            subsolver_options=IpoptOptions(hessian_approximation="limited-memory")
        ).first_order === true
    end

    @testset "kwargs passthrough to Pavito" begin
        o = PavitoIpoptCbcOptions(timeout=120.0, mip_solver_drives_time=false)
        @test o.nt == (timeout=120.0, mip_solver_drives_time=false)
        @test o.nt.timeout == 120.0
        # The subsolver options instance is stored as given.
        sub = IpoptOptions(first_order=true, max_iter=50)
        o2 = PavitoIpoptCbcOptions(subsolver_options=sub)
        @test o2.subsolver_options === sub
    end
end

@testitem "PavitoIpoptCbcOptions positional NamedTuple constructor" begin
    using NonconvexPavito, Test

    o = PavitoIpoptCbcOptions((; first_order=false, timeout=120.0))
    @test o.first_order === false
    @test o.nt == (timeout=120.0,)
    @test o.subsolver_options.nt.hessian_approximation == "exact"

    o2 = PavitoIpoptCbcOptions((; subsolver_options=IpoptOptions(first_order=false)))
    @test o2.first_order === false
    @test o2.nt == NamedTuple()

    o3 = PavitoIpoptCbcOptions((;))
    @test o3.first_order === true
    @test o3.nt == NamedTuple()
end

@testitem "continuous solve, result fields and no explicit start point" begin
    using NonconvexPavito, NonconvexCore, LinearAlgebra, Test
    import MathOptInterface as MOI

    alg = PavitoIpoptCbcAlg()
    f(x::AbstractVector) = (x[1] - 1)^2 + (x[2] - 2)^2
    quiet = PavitoIpoptCbcOptions(subsolver_options=IpoptOptions(print_level=0))

    @testset "PavitoIpoptCbcResult fields" begin
        m = Model(f)
        addvar!(m, [0.0, 0.0], [3.0, 3.0])
        r = NonconvexPavito.optimize(m, alg, [0.5, 0.5]; options=quiet)
        @test r isa NonconvexPavito.PavitoIpoptCbcResult
        @test r.minimizer isa Vector{Float64}
        @test r.minimum isa Float64
        @test r.problem isa NonconvexCore.JuMPProblem
        @test r.fcalls isa Int
        @test r.fcalls > 0
        @test r.status isa Tuple{MOI.TerminationStatusCode,MOI.ResultStatusCode}
        @test r.status[1] in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED)
        @test r.status[2] == MOI.FEASIBLE_POINT
        @test r.minimizer ≈ [1.0, 2.0] atol = 1e-6
        @test abs(r.minimum) < 1e-6
    end

    @testset "no explicit start point (getinit)" begin
        m = Model(x -> sum(abs2, x .- [1.0, 2.0]))
        addvar!(m, [0.0, 0.0], [3.0, 3.0]; init=[0.5, 0.5])
        r = NonconvexPavito.optimize(m, alg; options=quiet)
        @test r.minimizer ≈ [1.0, 2.0] atol = 1e-6
        @test abs(r.minimum) < 1e-6
    end
end

@testitem "mip sub-solver is Cbc" begin
    using NonconvexPavito, NonconvexCore, Test
    import JuMP
    import Cbc
    import MathOptInterface as MOI

    m = Model(x -> sum(abs2, x))
    addvar!(m, [0.0, 0.0], [3.0, 3.0])
    vecm, x0v, _ = NonconvexCore.tovecmodel(m)
    w = NonconvexPavito.PavitoIpoptCbcWorkspace(vecm, x0v; options=PavitoIpoptCbcOptions())
    backend = JuMP.backend(w.problem.model)
    mip = MOI.get(backend, MOI.RawOptimizerAttribute("mip_solver"))
    @test mip isa MOI.OptimizerWithAttributes
    @test mip.optimizer_constructor === Cbc.Optimizer
end

@testitem "solver capabilities (every field)" begin
    using NonconvexPavito, Test

    caps = solver_capabilities(PavitoIpoptCbcAlg())
    @test caps isa ConstraintCapabilities
    @test caps.linear_eq === true
    @test caps.nonlinear_eq === true
    @test caps.linear_ineq === true
    @test caps.nonlinear_ineq === true
    @test caps.linear_sd === false
    @test caps.nonlinear_sd === false
    @test caps.box === true
    @test caps.continuous === true
    @test caps.binary === true
    @test caps.integer === true
    @test caps.infinite_bounds === true
end

@testitem "start vector length mismatch" begin
    using NonconvexPavito, NonconvexCore, Test

    alg = PavitoIpoptCbcAlg()
    m = Model(x -> sum(abs2, x))
    addvar!(m, [0.0, 0.0], [3.0, 3.0])
    @test_throws AssertionError NonconvexPavito.optimize(m, alg, [1.0])
    vecm, _, _ = NonconvexCore.tovecmodel(m)
    @test_throws AssertionError NonconvexPavito.Workspace(vecm, alg, [1.0])
end
