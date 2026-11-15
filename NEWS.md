# NEWS

## 0.2.3

- Infeasible terminations without an incumbent return a NaN-filled
  result instead of throwing an opaque MOI exception.

## 0.2.2

- Respect the user `mip_solver` and harden the options handling; scheduled
  formatter workflow.

## 0.2.1

- Excluded Pavito.jl 0.3.2 (MOI 0.10 only); documented results and
  reexports; tested all exported features; organization logo; docs
  workflow fixes.

## 0.2.0

- NonconvexCore 2 with strict solver capability declarations
  (`infinite_bounds`); DocumenterFragments docs; tests migrated to
  TestItems with JET/Aqua/formatting quality gates; Julia 1.10+.

## 0.1.9

- Widened the compat bounds to include the latest dependency releases.

## 0.1.8

- Respect the explicit `first_order` option and use `JuMP.backend`, with
  regression tests.

## 0.1.7

- Fixed invalid stdlib compat bounds (`LinearAlgebra = "1.12.0 - 1"`) that
  accidentally shipped in 0.1.6 and made the package uninstallable on
  Julia 1.10/1.11.
- Requires Julia 1.10+.
