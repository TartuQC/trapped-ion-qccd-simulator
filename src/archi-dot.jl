# Architecture Design
# DOT's scratchpad

"""
## 3. Schedule data structure

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
    q₁ ::UInt16
    q₂ ::Uint16
    θ  ::Float32
end

"""
Struct `ZZ_t` — $e^{-i\pi\theta Z₁\otimes Z₂$ ...

... where 𝑍ᵢ refers to ion 𝑞ᵢ.
Subtype of `U_Oper_type`.
"""
struct ZZ_t <: U_Oper_type
    q₁ ::UInt16
    q₂ ::Uint16
    θ  ::Float32
end

"""
Struct `Rz_t` — 𝑍-axis Pauli rotation

Subtype of `U_Oper_type`.
"""
struct Rz_t <: U_Oper_type
    q ::UInt16
    θ  ::Float32
end

"""
Struct `Rxy_t` — Bloch sphere rotation

... with angle θ around the axis cosϕ ⋅ 𝑋 + sinϕ ⋅ 𝑌

Subtype of `U_Oper_type`.
"""
struct Rxy_t <: U_Oper_type
    q ::UInt16
    θ ::Float32
    ϕ ::Float64
end

#------------------------------------------------------------------------------------------
#
# Shuttling operations
#
#------------------------------------------------------------------------------------------

"""
Struct `Rxy_t` — Bloch sphere rotation

... with angle θ around the axis cosϕ ⋅ 𝑋 + sinϕ ⋅ 𝑌

Subtype of `U_Oper_type`.
"""
struct Load_t <: S_Oper_type
    q    ::UInt16
    zone ::Float32
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
