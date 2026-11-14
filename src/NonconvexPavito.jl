module NonconvexPavito

export PavitoIpoptCbcAlg, PavitoIpoptCbcOptions

using Pavito: Pavito
using Cbc: Cbc
using JuMP: JuMP
using MathOptInterface: MathOptInterface
using Ipopt: Ipopt
const MOI = MathOptInterface
using Reexport, Parameters
@reexport using NonconvexCore, NonconvexIpopt
using NonconvexCore: @params, AbstractOptimizer, AbstractResult
using NonconvexCore: VecModel, JuMPProblem, get_jump_problem
import NonconvexCore: optimize!, Workspace

function _warn_callback_ignored()
    @warn "The `callback` keyword is not supported by NonconvexPavito and will be ignored."
    return nothing
end
_warn_callback_ignored(nt::NamedTuple) = haskey(nt, :callback) && _warn_callback_ignored()

@params struct PavitoIpoptCbcOptions
    nt::NamedTuple
    subsolver_options::Any
    first_order::Bool
end
function PavitoIpoptCbcOptions(;
    first_order=nothing,
    subsolver_options=IpoptOptions(;
        first_order=first_order === nothing ? true : first_order
    ),
    kwargs...,
)
    return _pavito_ipopt_cbc_options((; first_order, subsolver_options, kwargs...))
end
# A positional-NamedTuple path: JET (on Julia 1.13) cannot resolve
# `Core.kwcall` on `Base.Pairs` forwarding during its virtual top-level
# replay, so forwarded options go through this positional method.
function PavitoIpoptCbcOptions(nt::NamedTuple)
    return _pavito_ipopt_cbc_options(nt)
end
function _pavito_ipopt_cbc_options(nt::NamedTuple)
    first_order = get(nt, :first_order, nothing)
    subsolver_options = get(
        nt,
        :subsolver_options,
        IpoptOptions(; first_order=first_order === nothing ? true : first_order),
    )
    # Only derive first_order from the subsolver options when it was not given
    # explicitly; an explicit first_order now always wins over a conflicting
    # hessian_approximation in subsolver_options.
    first_order = if first_order === nothing
        (
            !hasproperty(subsolver_options.nt, :hessian_approximation) ||
            subsolver_options.nt.hessian_approximation == "limited-memory"
        )
    else
        first_order
    end
    known = (:first_order, :subsolver_options)
    rest = [k for k in keys(nt) if k ∉ known]
    return PavitoIpoptCbcOptions(nt[Tuple(rest)], subsolver_options, first_order)
end

@params mutable struct PavitoIpoptCbcWorkspace <: Workspace
    model::VecModel
    problem::JuMPProblem
    x0::AbstractVector
    integers::AbstractVector{<:Bool}
    options::PavitoIpoptCbcOptions
    counter::Base.RefValue{Int}
end
function PavitoIpoptCbcWorkspace(
    model::VecModel,
    x0::AbstractVector=NonconvexCore.getinit(model);
    options=PavitoIpoptCbcOptions(),
    kwargs...,
)
    haskey(kwargs, :callback) && _warn_callback_ignored()
    ks = Tuple(k for k in keys(kwargs) if k !== :callback)
    rest = kwargs[ks]
    merged = isempty(rest) ? options : _pavito_merge_options(options, rest)
    return _pavito_ipopt_cbc_workspace(model, x0, merged)
end
# A positional-NamedTuple path: JET (on Julia 1.13) cannot resolve
# `Core.kwcall` on `Base.Pairs` forwarding during its virtual top-level
# replay, so forwarded options go through this positional method.
function PavitoIpoptCbcWorkspace(model::VecModel, x0::AbstractVector, nt::NamedTuple)
    _warn_callback_ignored(nt)
    ks = Tuple(k for k in keys(nt) if k !== :callback)
    opt_nt = nt[ks]
    options = if haskey(opt_nt, :options)
        rest = (; (k => v for (k, v) in pairs(opt_nt) if k !== :options)...)
        isempty(rest) ? opt_nt[:options] : _pavito_merge_options(opt_nt[:options], rest)
    else
        # Forward remaining keyword arguments (e.g. `mip_solver`) to the
        # options constructor; `callback` is handled above.
        PavitoIpoptCbcOptions(opt_nt)
    end
    return _pavito_ipopt_cbc_workspace(model, x0, options)
end
# Direct keyword arguments take precedence over an explicitly passed
# `options` object.
function _pavito_merge_options(options::PavitoIpoptCbcOptions, rest::NamedTuple)
    base = (;
        options.nt...,
        first_order=options.first_order,
        subsolver_options=options.subsolver_options,
    )
    return PavitoIpoptCbcOptions(; base..., rest...)
end
function _pavito_ipopt_cbc_workspace(
    model::VecModel, x0::AbstractVector, options::PavitoIpoptCbcOptions
)
    integers = model.integer
    @assert length(integers) == length(x0)
    nt1 = options.subsolver_options.nt
    ks = setdiff(keys(nt1), (:symbolic, :sparse))
    subsolver_options = Dict{String,Any}(string(k) => nt1[k] for k in ks)
    nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, subsolver_options...)
    nt2 = options.nt
    solver_options = Dict{String,Any}(string(k) => nt2[k] for k in keys(nt2))
    # A user-supplied `mip_solver` option takes precedence over the default
    # Cbc sub-solver. `JuMP.optimizer_with_attributes` is idempotent for
    # `MOI.OptimizerWithAttributes` and wraps plain optimizer constructors.
    mip_solver = pop!(solver_options, "mip_solver", nothing)
    mip_solver = if mip_solver === nothing
        JuMP.optimizer_with_attributes(Cbc.Optimizer)
    elseif mip_solver isa MOI.OptimizerWithAttributes
        mip_solver
    else
        JuMP.optimizer_with_attributes(mip_solver)
    end
    optimizer = JuMP.optimizer_with_attributes(
        Pavito.Optimizer,
        "cont_solver" => nl_solver,
        solver_options...,
        "mip_solver" => mip_solver,
    )
    objective = NonconvexCore.getobjective(model)
    objective === nothing && throw(ArgumentError("The model has no objective."))
    ineq = isempty(model.ineq_constraints.fs) ? nothing : model.ineq_constraints
    eq = isempty(model.eq_constraints.fs) ? nothing : model.eq_constraints
    obj = NonconvexCore.CountingFunction(objective)
    problem = NonconvexCore.get_jump_problem(
        obj,
        ineq,
        eq,
        copy(x0),
        integers,
        NonconvexCore.getmin(model),
        NonconvexCore.getmax(model),
        options.first_order,
        optimizer,
        NonconvexCore.DEFAULT_AD_BACKEND[],
    )
    return PavitoIpoptCbcWorkspace(model, problem, copy(x0), integers, options, obj.counter)
end
@params struct PavitoIpoptCbcResult <: AbstractResult
    minimizer::Any
    minimum::Any
    problem::Any
    status::Any
    fcalls::Int
end

function optimize!(workspace::PavitoIpoptCbcWorkspace)
    @unpack problem, options, x0, counter = workspace
    counter[] = 0
    jump_problem = workspace.problem
    jump_model = jump_problem.model
    moi_model = JuMP.backend(jump_model)
    MOI.set.(Ref(moi_model), Ref(MOI.VariablePrimalStart()), workspace.problem.vars, x0)
    MOI.optimize!(moi_model)
    minimizer = MOI.get(moi_model, MOI.VariablePrimal(), jump_problem.vars)
    objval = MOI.get(moi_model, MOI.ObjectiveValue())
    term_status = MOI.get(moi_model, MOI.TerminationStatus())
    primal_status = MOI.get(moi_model, MOI.PrimalStatus())
    return PavitoIpoptCbcResult(
        minimizer, objval, problem, (term_status, primal_status), counter[]
    )
end

struct PavitoIpoptCbcAlg <: AbstractOptimizer end

function NonconvexCore.solver_capabilities(::PavitoIpoptCbcAlg)
    return ConstraintCapabilities(;
        linear_eq=true,
        nonlinear_eq=true,
        linear_ineq=true,
        nonlinear_ineq=true,
        linear_sd=false,
        nonlinear_sd=false,
        box=true,
        continuous=true,
        binary=true,
        integer=true,
        infinite_bounds=true,
    )
end

function Workspace(
    model::VecModel, optimizer::PavitoIpoptCbcAlg, x0::AbstractVector; kwargs...
)
    return PavitoIpoptCbcWorkspace(model, x0, (; kwargs...))
end

# Without an explicit start point, default to the model's initial values.
function Workspace(model::VecModel, optimizer::PavitoIpoptCbcAlg; kwargs...)
    return PavitoIpoptCbcWorkspace(model, NonconvexCore.getinit(model), (; kwargs...))
end

end
