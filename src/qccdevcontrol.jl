# src/qccdevcontrol.jl
# Created by Dirk Oliver Theis, March 19, 2021
# MIT license
# Sub-module QCCDevCtrl

module QCCDevControl

export QCCDevCtrl

using ..QCCDevDes_Types
using ..QCCDevControl_Types

include("initFunctions.jl")

"""
This sub-module provides the type `QCCDevCtrl` and functions for controlling the operation of the
simulated quantum device.

# Exported
* Type `QCCDevCtrl` w/ constructor

# Not Exported Interface
* `load()`
* `linear_transport()`, `junction_transport()`,
* `swap()`
* `Rz()`, `Rxy()`, `XX()`, `ZZ()`

# Todo
* Visualization interface
"""



"""
Type for time inside the qdev, in [change if necessary]   10^{-10}
seconds, i.e., ns/10.  All times are ≥0; negative value of expressions
of this type are errors (and may carry local error information).
"""
const Time_t = Int64

struct QCCDevCtrl
    dev         ::QCCDevDescription
    max_capacity::Int64
    t_now       ::Time_t
# Descomment when load() function is done
#    qubits      ::Dict{String,Qubit}
    traps       ::Dict{Symbol,Trap}
    junctions   ::Dict{Symbol,Junction}
    shuttles    ::Dict{Symbol,Shuttle}
    graph       ::SimpleGraph{Int64}

    # Rest of struct contains description of current status of qdev
    # and its ions, such as the list of operations that are ongoing
    # right now.
end



####################################################################################################

"""
Function `QCCDevCtrl(::QCCDevDescription ; simulate::Bool, 𝑜𝑝𝑡𝑖𝑜𝑛𝑠)`

Constructor; initializes an "empty" QCCD as described, with no ions loaded (yet).

# Arguments

* `simulate` — If `simulate` is true, quantum circuit simulation is performed.

## Options:
* Currently none

"""
function QCCDevCtrl(qdd::QCCDevDescription ; simulate::Bool)::QCCDevCtrl
    # Initializes devices componentes
    junctions = _initJunctions(qdd.shuttle.shuttles, qdd.junction.junctions)
    shuttles = _initShuttles(qdd.shuttle)
    traps = _initTraps(qdd.trap)
    graph = initGraph(qdd)
    max_capacity = reduce(+,map(tr -> tr.capacity,collect(values(traps))))
    
    # Check errors
    _checkInitErrors(qdd.adjacency.nodes, traps, shuttles)

    # Initalizate QCCDevCtrl
    return QCCDevCtrl(qdd, max_capacity,0,traps,junctions,shuttles, graph)

    # Simulate
end

####################################################################################################

"""
Function `load()` — loads an ion into the device

# Arguments
* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.

The function returns the time at which the operation will be completed.
"""
function load(qdc           ::QCCDevCtrl,
              t             ::Time_t,
              loading_hole  ::Int       )  ::Time_t
    time_check(qdc)
    @assert 1 ≤ loading_hole ≤ dev.num_loading_holes
    load_checks()                      # todo
    # local t_end = compute_end_time()   # todo
    modify_status()                    # todo

    qdc.t_now = t
    return 0 # t_end
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
function linear_transport(qdc           :: QCCDevCtrl,
                          t             :: Time_t,
                          ion_idx       :: Int,
                          edge_idx      :: Int       ) ::Time_t
    
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
function junction_transport(qdc           :: QCCDevCtrl,
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
function swap(qdc           :: QCCDevCtrl,
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
function split(qdc           :: QCCDevCtrl,
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
function merge(qdc           :: QCCDevCtrl,
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
function Rz(qdc           :: QCCDevCtrl,
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
function Rxy(qdc           :: QCCDevCtrl,
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
function XX(qdc           :: QCCDevCtrl,
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
function ZZ(qdc           :: QCCDevCtrl,
            t             :: Time_t,
            ion1_idx      :: Int,
            ion2_idx      :: Int,
            θ             :: Real      ) ::Time_t
    # Attention: May not work on all devices
    
end

end #^ module QCCDevCtrl

# EOF
