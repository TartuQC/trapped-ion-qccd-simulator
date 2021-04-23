# Architecture Design
# DOT's scratchpad

"""
## 3. Schedule data structure

### Place in the software
- Created by "Mapping-Shuttling-Scheduling"
- Consumed by "Run", where the individual operations for the
n  HW/Simu/RE are issued

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

#
# These are temporary: When the types are available in
# "qccdevcontrol.jl", they will be `using'`d from there.
#
const QubitIdx    = Int32
const Edge_t      = Int32
const LoadZone_t  = Int32
const GateZone_t  = Int32


#------------------------------------------------------------------------------------------

"""
Abstract type `Oper_type` — supertype of all HW operations
"""
abstract type Oper_type                 end

"""
Abstract type `U_Oper_type` — supertype of all unitary HW operations.

Subtype of `Oper_type`.
"""
abstract type U_Oper_type <: Oper_type  end

"""
Abstract type `S_Oper_type` — supertype of all shuttling HW operations.

Subtype of `Oper_type`.
"""
abstract type S_Oper_type <: Oper_type  end

"""
Abstract type `M_Oper_type` — supertype of all measurement HW operations.

Subtype of `Oper_type`.
"""
abstract type M_Oper_type <: Oper_type  end

"""
Abstract type `C_Oper_type` — supertype of all classical control operations.

Subtype of `Oper_type`.
"""
abstract type C_Oper_type <: Oper_type  end

#------------------------------------------------------------------------------------------
#
# Unitary Operations (`U_Oper_type`)
#
#------------------------------------------------------------------------------------------

"""
Struct `XX_t` — $e^{-i\pi\theta X₁\otimes X₂$ ...

... where 𝑋ᵢ refers to ion 𝑞ᵢ.
Subtype of `U_Oper_type`.
"""
struct XX_t <: U_Oper_type
    q₁ ::QubitIdx
    q₂ ::QubitIdx
    θ  ::Float32
end

"""
Struct `ZZ_t` — $e^{-i\pi\theta Z₁\otimes Z₂$ ...

... where 𝑍ᵢ refers to ion 𝑞ᵢ.
Subtype of `U_Oper_type`.
"""
struct ZZ_t <: U_Oper_type
    q₁ ::QubitIdx
    q₂ ::QubitIdx
    θ  ::Float32
end

"""
Struct `Rz_t` — 𝑍-axis Pauli rotation

Subtype of `U_Oper_type`.
"""
struct Rz_t <: U_Oper_type
    q  ::QubitIdx
    θ  ::Float32
end

"""
Struct `Rxy_t` — Bloch sphere rotation

... with angle θ around the axis cosϕ ⋅ 𝑋 + sinϕ ⋅ 𝑌

Subtype of `U_Oper_type`.
"""
struct Rxy_t <: U_Oper_type
    q ::QubitIdx
    θ ::Float32
    ϕ ::Float64
end

#------------------------------------------------------------------------------------------
#
# Shuttling operations
#
#------------------------------------------------------------------------------------------

"""
Struct `Load_t` — load ion operation

... subtype of `S_Oper_type`.

(Note that the HW returns its own ion ID (of type `Int`), and that
that has to be mapped to the `q` field in the `Load_t` struct.)
"""
struct Load_t <: S_Oper_type
    q    ::QubitIdx
    zone ::LoadZone_t
end

"""
Struct `LinMove_t` — linear transport operation

... subtype of `S_Oper_type`.

"""
struct LinMove_t <: S_Oper_type
    q    ::QubitIdx
    edge ::Edge_t
end

"""
Struct `JunctionMove_t` — linear transport operation

... subtype of `S_Oper_type`.

"""
struct JunctionMove_t <: S_Oper_type
    q    ::QubitIdx
    edge ::Edge_t
end

"""
Struct `IonSwap_t` — ion-swap operation

... subtype of `S_Oper_type`.

"""
struct IonSwap_t <: S_Oper_type
    q₁  ::QubitIdx
    q₂  ::QubitIdx
end

"""
Struct `Split_t` — split ion off from gate zone

... subtype of `S_Oper_type`.

"""
struct Split_t <: S_Oper_type
    q    ::QubitIdx
    zone ::GateZone_t
end

"""
Struct `Merge_t` — merge ion into gate zone

... subtype of `S_Oper_type`.

"""
struct Merge_t <: S_Oper_type
    q    ::QubitIdx
    zone ::GateZone_t
end

#------------------------------------------------------------------------------------------
#
# Measurement Operations
#
#------------------------------------------------------------------------------------------

"""
Struct `Measure_t` — measure ion

... subtype of `M_Oper_type`.

"""
struct Measure_t <: M_Oper_type
    q ::QubitIdx
end

#------------------------------------------------------------------------------------------
#
# Classical Control Operations
#
#------------------------------------------------------------------------------------------

"""
Struct `Switch_t` — C-style switch-case statement

... subtype of `C_Oper_type`.

"""
struct Switch_t <: M_Oper_type
    q      ::Array{QubitIdx,1}
    case   ::Array{OpData,1}
end

#------------------------------------------------------------------------------------------
#
#
#
#------------------------------------------------------------------------------------------

struct OpData{OP <: Oper_type}
    t₀   :: Int64         # start time of op
    op   :: OP
end






end #^ module Schedule
#EOF
