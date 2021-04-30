# Architecture Design
# DOT's scratchpad

"""
## 1. Quantum circuit
## 2. Mapping, shuttling, scheduling
## ⮕ 3. Schedule data structure

### Place in the software
- Created by "Mapping-Shuttling-Scheduling"
- Consumed by "Run", where the individual operations for the
  HW/Simu/RE are issued

### Design goal
- Simple!  It's the output of a function that will be adapted by
  researchers.
- Direct construction & manipulation (i.e., not through service
  functions)

### Content
- Refers to one instance of QCCDevDescription
- All hw-gates & measurements (on ions) with scheduled times
- All shuttling operations with scheduled times

### Functions
- checkFeasible()
"""
module Schedule

using .QCCDevDes_Types: QCCDevDescription
using .QCCDevStatFeasible
using .QCCDevCtrl

import Base: showerror

#
# These are temporary: When the types are available in other parts of the code,
# they will be `using'`d from there.
#

# Defined hardware-side (e.g., "qccdevcontrol.jl")
const IonIdx            = Int64
const Edge_t            = Int32
const LoadZone_t        = Int32
const GateZone_t        = Int32

struct QCCDsim_Exception

# Defined user-side
const Logical_IonIdx    = Int32
const Measurement_ID_t  = Int64
# TODO
#
# In this version, measurement IDs have to be distinct: Two different physical measurements
# of qubits (or the same qubit at different times) must have distinct IDs.  As an
# enhancement, measurement IDs for several measurements may be the same.  Then, in the
# results, the entry of the corresponding ``avg''-array will be an assignment (e.g., Dict)
# which gives the fraction of occurrences for each combination of the outcomes.
#

###########################################################################################
#                                                                                         #
#  Hardware Operations Datastructures                                                     #
#                                                                                         #
###########################################################################################

struct Operation_Not_Supported <: QCCDsim_Exception
    txt ::String
end
showerror(e::Operation_Not_Supported) = println(e.txt)



"""
Abstract type `Operation_t` — supertype of all HW operations
"""
abstract type Operation_t                 end

"""
Abstract type `Unitary_Operation_t` — supertype of all unitary HW operations.

Subtype of `Operation_t`.
"""
abstract type Unitary_Operation_t <: Operation_t  end

"""
Abstract type `Shuttling_Operation_t` — supertype of all shuttling HW operations.

Subtype of `Operation_t`.
"""
abstract type Shuttling_Operation_t <: Operation_t  end

"""
Abstract type `Init_Operation_t` — supertype of all initialization HW operations.

Subtype of `Operation_t`.
"""
abstract type Init_Operation_t <: Operation_t  end

"""
Abstract type `Measurement_Operation_t` — supertype of all measurement HW operations.

Subtype of `Operation_t`.
"""
abstract type Measurement_Operation_t <: Operation_t  end

"""
Abstract type `ClCtrl_Operation_t` — supertype of all classical control operations.

Subtype of `Operation_t`.
"""
abstract type ClCtrl_Operation_t <: Operation_t  end

#------------------------------------------------------------------------------------------
#
# Unitary Operations (`Unitary_Operation_t`)
#
#------------------------------------------------------------------------------------------

"""
Struct `XX_t` — $e^{-i\pi\theta X₁\otimes X₂$ ...

... where 𝑋ᵢ refers to ion 𝑞ᵢ.
Subtype of `Unitary_Operation_t`.
"""
struct XX_t <: Unitary_Operation_t
    q₁ ::Logical_IonIdx
    q₂ ::Logical_IonIdx
    θ  ::Float32
end

function _exec1(qdc         ::QCCDevCtrl,
                phys_of_log ::Array{IonIdx,1},
                opd         ::OpData{XX_t}   ) ::Nothing
    physIon₁ = phys_of_log[opd.op.q₁]
    physIon₂ = phys_of_log[opd.op.q₂]
    @assert physIon₁ ≥ 1
    @assert physIon₂ ≥ 1

    if testing
        isallowed_XX(qdc, opd.t₀,
                     physIon₁, physIon₂, opd.op.θ)
    else
        XX(          qdc, opd.t₀,
                     physIon₁, physIon₂, opd.op.q₂, opd.op.θ)
    end
end


"""
Struct `ZZ_t` — $e^{-i\pi\theta Z₁\otimes Z₂$ ...

... where 𝑍ᵢ refers to ion 𝑞ᵢ.
Subtype of `Unitary_Operation_t`.
"""
struct ZZ_t <: Unitary_Operation_t
    q₁ ::Logical_IonIdx
    q₂ ::Logical_IonIdx
    θ  ::Float32
end

function _exec1(qdc         ::QCCDevCtrl,
                phys_of_log ::Array{IonIdx,1},
                opd         ::OpData{ZZ_t}   ) ::Nothing
    physIon₁ = phys_of_log[opd.op.q₁]
    physIon₂ = phys_of_log[opd.op.q₂]
    @assert physIon₁ ≥ 1
    @assert physIon₂ ≥ 1

    ZZ(qdc, opd.t₀,
       physIon₁, physIon₂, opd.op.θ)
end

"""
Struct `Rz_t` — 𝑍-axis Pauli rotation

Subtype of `Unitary_Operation_t`.
"""
struct Rz_t <: Unitary_Operation_t
    q  ::Logical_IonIdx
    θ  ::Float32
end

function _exec1(qdc         ::QCCDevCtrl,
                phys_of_log ::Array{IonIdx,1},
                 opd        ::OpData{Rz_t}   ) ::Nothing
    physIon = phys_of_log[opd.op.q]
    @assert physIon ≥ 1

    Rz(qdc, opd.t₀,
       physIon, opd.op.θ)
    nothing;
end

"""
Struct `Rxy_t` — Bloch sphere rotation

... with angle θ around the axis cosϕ ⋅ 𝑋 + sinϕ ⋅ 𝑌

Subtype of `Unitary_Operation_t`.
"""
struct Rxy_t <: Unitary_Operation_t
    q ::Logical_IonIdx
    θ ::Float32
    ϕ ::Float64
end

function _exec1(qdc         ::QCCDevCtrl,
                phys_of_log ::Array{IonIdx,1},
                opd         ::OpData{Rxy_t}  ) ::Nothing
    physIon = phys_of_log[opd.op.q]
    @assert physIon ≥ 1

    Rxy(qdc, opd.t₀,
        physIon, opd.op.ϕ, opd.op.θ)
    nothing;
end

#------------------------------------------------------------------------------------------
#
# Shuttling operations
#
#------------------------------------------------------------------------------------------

"""
Struct `Load_t` — load ion operation

... subtype of `Shuttling_Operation_t`.

(Note that the HW returns its own ion ID (of type `Int`), and that
that has to be mapped to the `q` field in the `Load_t` struct.)
"""
struct Load_t <: Shuttling_Operation_t
    q    ::Logical_IonIdx
    zone ::LoadZone_t
end

function _exec1(qdc         ::QCCDevCtrl,
                phys_of_log ::Array{IonIdx,1},
                opd         ::OpData{Load_t} ) ::Nothing
    @assert phys_of_log[opd.op.q] == -1  "Ion already in use!"

    nt = load(qdc, opd.t₀,
              opd.zone)
    phys_of_log[opd.op.q] = nt.new_ion_idx
    nothing;
end

"""
Struct `LinMove_t` — linear transport operation

... subtype of `Shuttling_Operation_t`.

"""
struct LinMove_t <: Shuttling_Operation_t
    q    ::Logical_IonIdx
    edge ::Edge_t
end

function _exec1(qdc         ::QCCDevCtrl,
                phys_of_log ::Array{IonIdx,1},
                opd         ::OpData{LinMove_t}) ::Nothing
    physIon = phys_of_log[opd.op.q]
    @assert physIon ≥ 1

    linear_transport(qdc, opd.t₀,
                     physIon, opd.edge)
    nothing;
end

"""
Struct `JunctionMove_t` — linear transport operation

... subtype of `Shuttling_Operation_t`.

"""
struct JunctionMove_t <: Shuttling_Operation_t
    q    ::Logical_IonIdx
    edge ::Edge_t
end

function _exec1(qdc         ::QCCDevCtrl,
                phys_of_log ::Array{IonIdx,1},
                opd         ::OpData{JunctionMove_t}) ::Nothing
    physIon = phys_of_log[opd.op.q]
    @assert physIon ≥ 1

    junction_transport(qdc, opd.t₀,
                       physIon, opd.edge)
    nothing;
end

"""
Struct `IonSwap_t` — ion-swap operation

... subtype of `Shuttling_Operation_t`.

"""
struct IonSwap_t <: Shuttling_Operation_t
    q₁  ::Logical_IonIdx
    q₂  ::Logical_IonIdx
end

function _exec1(qdc         ::QCCDevCtrl,
                phys_of_log ::Array{IonIdx,1},
                opd         ::OpData{IonSwap_t}) ::Nothing
    physIon₁ = phys_of_log[opd.op.q₁]
    physIon₂ = phys_of_log[opd.op.q₂]
    @assert physIon₁ ≥ 1
    @assert physIon₂ ≥ 1

    swap(qdc, opd.t₀,
         physIon₁, physIon₂)
end

"""
Struct `Split_t` — split ion off from gate zone

... subtype of `Shuttling_Operation_t`.

"""
struct Split_t <: Shuttling_Operation_t
    q    ::Logical_IonIdx
    zone ::GateZone_t
end

function _exec1(qdc         ::QCCDevCtrl,
                phys_of_log ::Array{IonIdx,1},
                opd         ::OpData{Split_t}) ::Nothing
    physIon = phys_of_log[opd.op.q]
    @assert physIon ≥ 1

    split(qdc, opd.t₀,
          physIon, opd.zone)
    nothing;
end

"""
Struct `Merge_t` — merge ion into gate zone

... subtype of `Shuttling_Operation_t`.

"""
struct Merge_t <: Shuttling_Operation_t
    q    ::Logical_IonIdx
    zone ::GateZone_t
end

function _exec1(qdc         ::QCCDevCtrl,
                phys_of_log ::Array{IonIdx,1},
                opd         ::OpData{Merge_t}) ::Nothing
    physIon = phys_of_log[opd.op.q]
    @assert physIon ≥ 1

    merge(qdc, opd.t₀,
          physIon, opd.zone)
    nothing;
end

#------------------------------------------------------------------------------------------
#
# Initialization Operations
#
#------------------------------------------------------------------------------------------

"""
Struct `Reset_t` — prepare qubit in ion in state |0⟩.

... subtype of `Init_Operation_t`.
"""
struct Reset_t <: Init_Operation_t
    q ::Logical_IonIdx
end

function _exec1(qdc         ::QCCDevCtrl,
                phys_of_log ::Array{IonIdx,1},
                opd         ::OpData{Reset_t}) ::Nothing
    physIon = phys_of_log[opd.op.q]
    @assert physIon ≥ 1

    qubit_reset(qdc, opd.t₀,
                physIon)
    nothing;
end

#------------------------------------------------------------------------------------------
#
# Measurement Operations
#
#------------------------------------------------------------------------------------------

"""
Struct `Measure_t` — measure ion

... subtype of `Measurement_Operation_t`.
"""
struct Measure_t <: Measurement_Operation_t
    q   ::Logical_IonIdx
    mID ::Measurement_ID_t
end

function _exec1(qdc         ::QCCDevCtrl,
                phys_of_log ::Array{IonIdx,1},
                opd         ::OpData{Measure_t}) ::Int
    physIon = phys_of_log[opd.op.q]
    @assert physIon ≥ 1

    return Int(
        measure(qdc, opd.t₀,
                physIon).result
    )
end

#------------------------------------------------------------------------------------------
#
# Classical Control Operations
#
#------------------------------------------------------------------------------------------

"""
Struct `ClassicalCtrl_t` — fully general classical control

... subtype of `ClCtrl_Operation_t`.

# Fields
- `q`: Array of qubit indices
- `f`: Function with signature
```julia
         f( ; qubits  ::Array{Logical_IonIdx,1},
              results ::Array{Int8,1}    ) ::Array{OpData,1}
```
- `tₘₐₓ`: time

# Semantics & requirements

The semantics of operations of this type is as follows.
1. The qubits in the array `q` will be measured in the 𝑍-basis.
2. The function `f` will be called with the array `q` and the results.
3. The operations returned by `f` will be executed; the time entry in the `OpData`s must be
   relative to the time when the measurements are completed, i.e., time t₀=0 refers to the
   first moment in time when an operation depending on the measurement outcomes is possible.

The requirements are:

4. The worst-case duration of the op-data array returned by `f` (including finishing the
   "last" operation) must be less than or equal to `tₘₐₓ`.
5. The operations returned by `f` must **not** include any measurements
   (`Measurement_Operation_t`) or classical control (`ClCtrl_Operation_t`).

The measurement results are not recorded in the list of measurement results in any of the
`execute()` functions.

"""
struct ClassicalCtrl_t <: ClCtrl_Operation_t
    q      ::Array{Logical_IonIdx,1}
    f      ::Function
    tₘₐₓ   ::Time_t
end

###########################################################################################
#                                                                                         #
#  Schedule Data Structures                                                               #
#                                                                                         #
###########################################################################################

struct OpData{OP <: Operation_t}
    t₀   :: Time_t         # start time of op
    op   :: OP
end

struct OpSchedule
    n_log_ions ::Int
    item       ::Array{OpData}
end

###########################################################################################
#                                                                                         #
#  Results Data Structures                                                                #
#                                                                                         #
###########################################################################################

struct Measurement_Results_t
    ids ::Array{Measurement_ID_t,1}
    avg ::Array{Float64,1}
end


###########################################################################################
#                                                                                         #
#  Execution and Test Functions                                                           #
#                                                                                         #
###########################################################################################

function execute!(qdevdescr       :: QCCDevDescription
                  sch             :: OpSchedule
                  ;
                  simulate        :: Symbol = :PureStates,
                  qnoise_estimate :: Bool   = false      ) ::Measurement_Results_t

    qdc = QCCDevCtrl(qdevdescr ;
                     simulate, qnoise_estimate)

    return _execute_do(qdc, sch)
end

function test!(sch ::OpSchedule ) ::Nothing

    qdc = QCCDevCtrl(qdevdescr ;
                     simulate=:No, qnoise_estimate=false)

    _execute_do(qdc, sch)

    nothing
end


function _execute_do(qdc ::QCCDevCtrl,
                     sch ::OpSchedule)  ::Measurement_Results_t

    local phys_of_log = [ IonIdx(-1)    for j in 1:sch.n_log_ions ]
    local measRes     = Dict{ Measurement_ID_t, @NamedTuple{count::Int,sum::Int} }()

    for item in sch.item
        if isa(item.op, Measurement_Operation_t)
            local measDat = get!(measRes, item.op.mID, (count=0,sum=0))
            local bit = exec1(qdc,phys_of_log,item)
            @assert bit ∈ [0,1]    "BUG: QCCDevCtrl.measure() returned a result that's not 0/1"
            measRes[item.op.mID] = (count=measDat.count+1, sum=measDat.sum+bit)
        elseif isa(item.op, ClCtrl_Operation_t)
            throw Operation_Not_Supported("Classical control operations are not yet implemented")
        else
            _exec1(qdc,phys_of_log, item)
        end
    end
end

end #^ module Schedule
#EOF
