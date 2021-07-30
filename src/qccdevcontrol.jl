# src/qccdevcontrol.jl
# Created by Dirk Oliver Theis, March 19, 2021
# MIT license
# Sub-module QCCDevCtrl

module QCCDDevControl

using LightGraphs: length
export QCCDevCtrl

using ..QCCDevDes_Types
using ..QCCDevControl_Types
using ..QCCDev_Utils
using ..QCCDev_Feasible

include("initFunctions.jl")
include("devCtrlAux.jl")
"""
This sub-module provides the type `QCCDevCtrl` and functions for controlling the operation of the
simulated quantum device.

# Exported
- `QCCDevCtrl()`

# Not Exported Interface
- `load()`
- `linear_transport()`, `junction_transport()`,
- `swap()`
- `Rz()`, `Rxy()`, `XX()`, `ZZ()`



# Todo
* Visualization interface
"""

struct QCCDevCtrl__Operation_Not_Allowed_Exception end


####################################################################################################

"""
Function `QCCDevCtrl(::QCCDevDescription ; simulate::Symbol, 𝑜𝑝𝑡𝑖𝑜𝑛𝑠)`

Constructor; initializes an "empty" QCCD as described, with no ions loaded (yet).

# Arguments

- `simulate::Symbol` — one of `:No`, `:PureStates`, `:MixedStates`
- `qnoise_estimate::Bool` — whether estimation of noise takes place

Setting both `simulate=:No` and `qnoise_estimate=false` allows
feasibility check of a schedule.

## Options:
Currently none.  Possible:
- Modify default noise model (in case of `:MixedStates` simulation
- Modify default qnoise parameters
"""
function QCCDevCtrl(qdd             ::QCCDevDescription
                    ;
                    simulate ::Symbol = :No,
                    qnoise_estimate::Bool = false        ) ::QCCDevControl

    @assert simulate        ∈ [:No, :PureStates, :MixedStates]
    @assert qnoise_estimate ∈ [true,false] # 😃

    #-------------------------------------------------------------------#
    # TODO                                                              #
    #                                                                   #
    # Check whether simulation resources are sufficient to accommodate  #
    # the number of qubits (in pure states, mixed states, or tensor     #
    # network (cuQuantum) simulation)                                   #
    #                                                                   #
    #-------------------------------------------------------------------#

    # Initializes devices components
    gateZones = _initGateZone(qdd.gateZone)
    junctions = _initJunctions(qdd.gateZone.gateZones, qdd.auxZone.auxZones, qdd.loadZone.loadZones, qdd.junction.junctions)
    auxZones = _initAuxZones(qdd.auxZone)
    loadingZones = _initLoadingZones(qdd.loadZone)

    # graph = initGraph(qdd)

    # Check errors
    _checkInitErrors(junctions, auxZones, gateZones, loadingZones)

    # Initalizate QCCDevCtrl
    return QCCDevControl(qdd,
                      simulate, qnoise_estimate,
                      gateZones,junctions,auxZones, loadingZones)
end #^ QCCDevCtrl()

####################################################################################################

"""
Function `load()` — loads an ion into the device

# Arguments
* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.

The function returns a named tuple consisting of:
- `new_ion_idx` — the index identifying the new ion
- `t₀` — the time at which the loaded ion will be usable (for transport off the loading zone);
"""
function load(qdc           ::QCCDevControl,
              t             ::Time_t,
              loading_zone  ::Symbol       )  ::@NamedTuple{new_ion_idx::Int,t₀::Time_t}
 
  # Checks
  isallowed_load(qdc, loading_zone, t)

  # Create new qubit
  local qubit = initQubit(loading_zone)
  qdc.qubits[qubit.id] = deepcopy(qubit)
  qdc.loadingZones[loading_zone].hole = qubit.id
  
  # Compute and update time
  local t₀ = compute_time(qdc, t, OperationTimes[:load])
  
  return (new_ion_idx=qubit.id, t₀)
end #^ module 
# EOF

####################################################################################################

"""
Function `linear_transport()` — moves ions between zones/junctions.

# Arguments
* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.
* `ion_idx`   — index (1-based) of ion to be moved.
* `edge-idx`  — index (1-based) of destination zone.

The function returns the time at which the operation will be completed.
"""

function linear_transport(qdc           :: QCCDevControl,
                          t             :: Time_t,
                          ion_idx       :: Int,
                          destination_idx      :: Symbol) ::Time_t
  # Checks  
  isallowed_linear_transport(qdc, t, ion_idx, destination_idx)

  # Remove ion from origin, insert it to destination,
  # and check if it has arrived to its destination
  _move_ion(qdc, ion_idx, destination_idx)

  # Compute and update time
  local t₀ = compute_time(qdc, t, OperationTimes[:linear_transport])

  return t₀
end

####################################################################################################

"""
Function `junction_transport()` — moves around a junction.

# Arguments
* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.
* `ion_idx`   — index (1-based) of ion to be moved.
* `edge_idx` — index (1-based) of destination zone.

The function returns the time at which the operation will be completed.
"""
function junction_transport(qdc           :: QCCDevControl,
                            t             :: Time_t,
                            ion_idx       :: Int,
                            destination_idx      :: Symbol       ) ::Time_t
  # Checks
  isallowed_junction_transport(qdc, t, ion_idx, destination_idx)
  
  # Remove ion from origin, insert it to destination,
  # and check if it has arrived to its destination
  _move_ion_junction(qdc, ion_idx, destination_idx)

  # Compute and update time
  local t₀ = compute_time(qdc, t, OperationTimes[:junction_transport])

  return t₀
end



####################################################################################################

"""
Function `swap()` — physically swaps the positions of two ions

# Arguments
* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.
* `ion𝑖_idx`, 𝑖=1,2, the (1-based) indices of the two ions.  Must be in the same gate zone.

The function returns the time at which the operation will be completed.
"""
function swap(qdc           :: QCCDevControl,
              t             :: Time_t,
              ion1_idx      :: Int,
              ion2_idx      :: Int       ) ::Time_t
  # Checks
  isallowed_swap_split(qdc, ion1_idx, ion2_idx, t)

  # Swap qubits
  _swap_ions(qdc, ion1_idx, ion2_idx)

  # Compute and update time
  local t₀ = compute_time(qdc, t, OperationTimes[:swap])

  return t₀
end

####################################################################################################

"""
Function `split()` — Split chain

# Arguments


* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.
* `ion_idx` (1-based) index of the ion.
* `edge_idx` (1-based) index of edge at the end of which the ion will sit after split.

The function returns the time at which the operation will be completed.
"""
function split(qdc           :: QCCDevControl,
               t             :: Time_t,
               ion1_idx       :: Int,
               ion2_idx      :: Int) ::Time_t
  # Checks
  isallowed_swap_split(qdc, ion1_idx, ion2_idx, t; split=true)

  # Compute and actualize time
  local t₀ = compute_time(qdc, t, OperationTimes[:split])

  return t₀
end

####################################################################################################

"""
Function `merge()` — move ion out of gate zone into edge

# Arguments
* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.
* `ion_idx`   — (1-based) index of the ion.
* `edge_idx`  — (1-based) index of edge at the end of which the ion sits before merge.

The function returns the time at which the operation will be completed.
"""
function merge(qdc           :: QCCDevControl,
               t             :: Time_t,
               ion_idx       :: Int,
               edge_idx      :: Int) ::Time_t
    
end

####################################################################################################

"""
Function `Rz` — single qubit Z-rotation

# Arguments
* `t::Time_t`   — time at which the operation commences.  Must be no earlier than
  the latest time given to previous function calls.
* `ion_idx`     — (1-based) index of the ion.
* `θ`           — rotation angle

The function returns the time at which the operation will be completed.
"""
function Rz(qdc           :: QCCDevControl,
            t             :: Time_t,
            ion_idx       :: Int,
            θ             :: Real      ) ::Time_t
    
end

####################################################################################################

"""
Function `Rxy` — single qubit XY-plane rotation

# Arguments
* `t::Time_t`   — time at which the operation commences.  Must be no earlier than
  the latest time given to previous function calls.
* `ion_idx`     — (1-based) index of the ion.
* `ϕ`           — rotation axis is cos(phi)cdot sigma_x + sin(phi)cdot sigma_y
* `θ`           — rotation angle

The function returns the time at which the operation will be completed.
"""
function Rxy(qdc           :: QCCDevControl,
             t             :: Time_t,
             ion_idx       :: Int,
             ϕ             :: Real,
             θ             :: Real      ) ::Time_t
    # Attention: Not all values of ϕ may work for the device
    
end

####################################################################################################

"""
Function `XX` — two qubit XX-rotation

# Arguments
* `t::Time_t`      — time at which the operation commences.  Must be no earlier than
  the latest time given to previous function calls.
* `ion𝑖_idx`, 𝑖=1,2 — the (1-based) indices of the two ions.  Must be in the same gate zone.
* `θ`              — rotation angle

The function returns the time at which the operation will be completed.
"""
function XX(qdc           :: QCCDevControl,
            t             :: Time_t,
            ion1_idx      :: Int,
            ion2_idx      :: Int,
            θ             :: Real      ) ::Time_t
    # Attention: May not work on all devices
    
end

####################################################################################################

"""
Function `ZZ` — two qubit ZZ-rotation

# Arguments
* `t::Time_t`      — time at which the operation commences.  Must be no earlier than
  the latest time given to previous function calls.
* `ion𝑖_idx`, 𝑖=1,2 — the (1-based) indices of the two ions.  Must be in the same gate zone.
* `θ`              — rotation angle

The function returns the time at which the operation will be completed.
"""
function ZZ(qdc           :: QCCDevControl,
            t             :: Time_t,
            ion1_idx      :: Int,
            ion2_idx      :: Int,
            θ             :: Real      ) ::Time_t
    # Attention: May not work on all devices
    
end

end #^ module QCCDevCtrl

# EOF
