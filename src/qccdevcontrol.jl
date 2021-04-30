# src/qccdevcontrol.jl
# Created by Dirk Oliver Theis, March 19, 2021
# MIT license
# Sub-module QCCDevCtrl

module QCCDDevControl

export QCCDevCtrl

using ..QCCDevDes_Types
using ..QCCDevControl_Types
using ..QCCDev_Feasible


include("initFunctions.jl")

"""
This sub-module provides the type `QCCDevCtrl` and functions for controlling the operation of the
simulated quantum device.

# Exported
* `QCCDevCtrl()`

# Not Exported Interface
- `load()`
- `linear_transport()`, `junction_transport()`,
- `swap()`
- `Rz()`, `Rxy()`, `XX()`, `ZZ()`



# Todo
* Visualization interface
"""


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
                    simulate=:No        ::Symbol,
                    qnoise_estimate=false ::Bool             ) ::QCCDevControl

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

    # Initializes devices componentes
    junctions = _initJunctions(qdd.shuttle.shuttles, qdd.junction.junctions)
    shuttles = _initShuttles(qdd.shuttle)
    traps = _initTraps(qdd.trap)
    graph = initGraph(qdd)
    max_capacity = reduce(+,map(tr -> tr.capacity,collect(values(traps))))

    # Check errors
    _checkInitErrors(qdd.adjacency.nodes, traps, shuttles)

    # Initalizate QCCDevCtrl
    return QCCDevControl(qdd,
                      max_capacity,
                      simulate, qnoise_estimate,
                      traps,junctions,shuttles, graph)
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
              loading_zone  ::Any       )  ::@NamedTuple{new_ion_idx::Int,t₀::Time_t}

# TODO: Replace `Any` by correct type

    @assert 0 ≤ t            ≤ qdc.t_now
    # ⟶  isallowed...:  @assert 1 ≤ loading_zone ≤ dev.num_loading_zones

    if ! isallowed_load(qdc, t, loading_zone)
        throw(QCCDevCtrl__Operation_Not_Allowed_Exception())
    end

    local t₀ =
        compute_end_time() ::Time_t            # todo


    local new_ion_idx =
        do_the_work()  ::Int

    @assert t₀ > t                             "Something went horribly wrong: Time has stopped!"
    @assert new_ion_idx > 0                    "New ion index is ≤ 0 WTF!"

    modify_status()                            # todo

    qdc.t_now = t

    return (new_ion_idx=new_ion_idx, t₀=t₀)
end #^ module
# EOF

####################################################################################################

"""
Function `linear_transport()` — moves ions between zones/junctions.

# Arguments
* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.
* `ion_idx`   — index (1-based) of ion to be moved.
* `edge-idx`  — index (1-based) of edge to move along.

The function returns the time at which the operation will be completed.
"""
function linear_transport(qdc           :: QCCDevControl,
                          t             :: Time_t,
                          ion_idx       :: Int,
                          edge_idx      :: Int       ) ::Time_t
    
end

####################################################################################################

"""
Function `loadingHole_transport()` — moves ions from loading holes to gate zones.

# Arguments
* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.
* `ion_idx`   — index (1-based) of ion to be moved.
* `edge-idx`  — index (1-based) of edge to move along.

The function returns the time at which the operation will be completed.
"""
function loadingHole_transport(qdc           :: QCCDevControl,
                          t             :: Time_t,
                          ion_idx       :: Int,
                          trap_idx      :: Int       ) ::Time_t
  
  isallowed_loadingHole_transport(qdc, t, ion_idx, trap_idx)
    
  compute_end_time()

  get_Qerrors()
  
  qdc.traps[trap_idx].loading_hole[2] = nothing
  
  qdc.qubits[ion_idx].status = :inGateZone

  qdc.t_now = foo

  modify_QDC() # Change time, qubit status and place, update cummulative Q error?


end

####################################################################################################

"""
Function `junction_transport()` — moves around a junction.

# Arguments
* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.
* `ion_idx`   — index (1-based) of ion to be moved.
* `edge_idx` — index (1-based) of edge identifying the edge on which the ion leaves the junction.

The function returns the time at which the operation will be completed.
"""
function junction_transport(qdc           :: QCCDevControl,
                            t             :: Time_t,
                            ion_idx       :: Int,
                            edge_idx      :: Int       ) ::Time_t
    
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
    
end

####################################################################################################

"""
Function `split()` — move ion out of gate zone into edge

# Arguments


* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.
* `ion_idx` (1-based) index of the ion.
* `edge_idx` (1-based) index of edge at the end of which the ion will sit after split.

The function returns the time at which the operation will be completed.
"""
function split(qdc           :: QCCDevControl,
               t             :: Time_t,
               ion_idx       :: Int,
               edge_idx      :: Int) ::Time_t
    
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
