@testitem "First order variants" begin
    using NonconvexPavito, LinearAlgebra, Test

    f(x::AbstractVector) = sqrt(x[2])
    g(x::AbstractVector, a, b) = (a * x[1] + b)^3 - x[2]

    for first_order in [true, false]
        options = PavitoIpoptCbcOptions(first_order=first_order)
        @testset "Simple constraints" begin
            m = Model(f)
            addvar!(m, [0.0, 0.0], [10.0, 10.0])
            add_ineq_constraint!(m, x -> g(x, 2, 0))
            add_ineq_constraint!(m, x -> g(x, -1, 1))

            alg = PavitoIpoptCbcAlg()

            setinteger!(m, 1, true)
            r1 = optimize(m, alg, [1.234, 2.345], options=options)
            @test r1.minimizer[1] - round(Int, r1.minimizer[1]) ≈ 0 atol = 1e-7

            setinteger!(m, 1, false)
            setinteger!(m, 2, true)
            r2 = optimize(m, alg, [1.234, 2.345], options=options)
            @test r2.minimizer[2] - round(Int, r2.minimizer[2]) ≈ 0 atol = 1e-7
        end

        @testset "Block constraints" begin
            m = Model(f)
            addvar!(m, [0.0, 0.0], [10.0, 10.0])
            add_ineq_constraint!(m, FunctionWrapper(x -> [g(x, 2, 0), g(x, -1, 1)], 2))

            alg = PavitoIpoptCbcAlg()

            setinteger!(m, 1, true)
            r1 = optimize(m, alg, [1.234, 2.345], options=options)
            @test r1.minimizer[1] - round(Int, r1.minimizer[1]) ≈ 0 atol = 1e-7

            setinteger!(m, 1, false)
            setinteger!(m, 2, true)
            r2 = optimize(m, alg, [1.234, 2.345], options=options)
            @test r2.minimizer[2] - round(Int, r2.minimizer[2]) ≈ 0 atol = 1e-7
        end

        @testset "Infinite bounds" begin
            m = Model(f)
            addvar!(m, [0.0, 0.0], [Inf, Inf])
            add_ineq_constraint!(m, x -> g(x, 2, 0))
            add_ineq_constraint!(m, x -> g(x, -1, 1))

            alg = PavitoIpoptCbcAlg()

            setinteger!(m, 1, true)
            r1 = optimize(m, alg, [1.234, 2.345], options=options)
            @test r1.minimizer[1] - round(Int, r1.minimizer[1]) ≈ 0 atol = 1e-7

            setinteger!(m, 1, false)
            setinteger!(m, 2, true)
            r2 = optimize(m, alg, [1.234, 2.345], options=options)
            @test r2.minimizer[2] - round(Int, r2.minimizer[2]) ≈ 0 atol = 1e-7
        end
    end
end

@testitem "first_order precedence" begin
    using NonconvexPavito, Test

    # Regression test: an explicit first_order used to be overridden by a
    # conflicting hessian_approximation in subsolver_options.
    o = PavitoIpoptCbcOptions(
        first_order=true, subsolver_options=IpoptOptions(first_order=false)
    )
    @test o.first_order == true
    # Without an explicit first_order, the fallback derives it from the
    # subsolver options.
    o = PavitoIpoptCbcOptions(subsolver_options=IpoptOptions(first_order=false))
    @test o.first_order == false
end

@testitem "solver capabilities" begin
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
    @test caps.integer === true
end

@testitem "user mip_solver takes precedence" begin
    using NonconvexPavito, Test
    import Cbc, JuMP, MathOptInterface, NonconvexCore
    const MOI = MathOptInterface

    f(x::AbstractVector) = sum(x .^ 2)
    g(x::AbstractVector, a, b) = (a * x[1] + b)^3 - x[2]

    m = Model(f)
    addvar!(m, [0.0, 0.0], [10.0, 10.0])
    add_ineq_constraint!(m, x -> g(x, 2, 0))
    vm, x0, _ = NonconvexCore.tovecmodel(m, [1.0, 2.0])

    # The default MIP sub-solver is Cbc.
    w = Workspace(vm, PavitoIpoptCbcAlg(), x0)
    opt = JuMP.unsafe_backend(w.problem.model)
    @test MOI.get(opt, MOI.RawOptimizerAttribute("mip_solver")) isa MOI.OptimizerWithAttributes

    # A user-supplied mip_solver must not be overridden by the Cbc default.
    user_mip = JuMP.optimizer_with_attributes(Cbc.Optimizer)
    w = Workspace(vm, PavitoIpoptCbcAlg(), x0; mip_solver=user_mip)
    opt = JuMP.unsafe_backend(w.problem.model)
    @test MOI.get(opt, MOI.RawOptimizerAttribute("mip_solver")) === user_mip
end

@testitem "callback kwarg is not silently dropped" begin
    using NonconvexPavito, Test
    import NonconvexCore

    f(x::AbstractVector) = sum(x .^ 2)
    g(x::AbstractVector, a, b) = (a * x[1] + b)^3 - x[2]

    m = Model(f)
    addvar!(m, [0.0, 0.0], [10.0, 10.0])
    add_ineq_constraint!(m, x -> g(x, 2, 0))
    vm, x0, _ = NonconvexCore.tovecmodel(m, [1.0, 2.0])

    @test_logs (:warn, r"callback") match_mode=:any Workspace(
        vm, PavitoIpoptCbcAlg(), x0; callback=x -> nothing
    )
    @test_logs (:warn, r"callback") match_mode=:any Workspace(
        vm, PavitoIpoptCbcAlg(); callback=x -> nothing
    )
end

@testitem "direct option kwargs populate the options" begin
    using NonconvexPavito, Test
    import NonconvexCore

    f(x::AbstractVector) = sum(x .^ 2)
    g(x::AbstractVector, a, b) = (a * x[1] + b)^3 - x[2]

    m = Model(f)
    addvar!(m, [0.0, 0.0], [10.0, 10.0])
    add_ineq_constraint!(m, x -> g(x, 2, 0))
    vm, x0, _ = NonconvexCore.tovecmodel(m, [1.0, 2.0])

    # default options are first-order
    w = Workspace(vm, PavitoIpoptCbcAlg(), x0)
    @test w.options.first_order === true
    # a direct kwarg reaches the options instead of being dropped
    w = Workspace(vm, PavitoIpoptCbcAlg(), x0; first_order=false)
    @test w.options.first_order === false
    # an explicit options argument is still honored, and direct kwargs win
    w = Workspace(vm, PavitoIpoptCbcAlg(), x0; options=PavitoIpoptCbcOptions(), first_order=false)
    @test w.options.first_order === false
end
