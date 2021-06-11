# src/qccdevcontrol.jl
# Created by Anabel Ovide and Alejandro Villoria, 23 April, 2021
# MIT license
# Sub-module QCCDevCtrl

module QCCDev_Feasible
export load_checks, OperationNotAllowedException, isallowed_load, isallowed_linear_transport
export isallowed_junction_transport

using ..QCCDevDes_Types
using ..QCCDevControl_Types
using ..QCCDev_Utils

"""
Default error message for QCCD operations.
"""
struct OperationNotAllowedException <: Exception
  msg ::String
end

"Nicer way to throw error"
opError(x) = throw(OperationNotAllowedException(x))

"""
Function `time_check()` — checks if given time is correct

# Arguments
* `qdc:: Time_t` — Actual qdc device's time.
* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.

The function throws an error if time is not correct.
"""
function _time_check(t_qdc:: Time_t, t::Time_t, id::Symbol) 
  0 ≤ t_qdc ≤ t  || opError("Time must be higher than $t_qdc")
  haskey(OperationTimes, id) || opError("Time model for $id not defined.")
end

"""
Function `isallowed_load()` — checks if load operation is posisble

# Arguments
* `qdc::QCCDevControl` — Actual device's status.
* `loading_zone::Symbol` — Desired place to load an ion
* `t::Time_t` — Time at which the operation commences.  Must be no earlier than the latest time
                given to previous function calls.
# checks
* Check time — Call _time_check function.
* Check maximum capacity — Check device's maximum capacity is not exeeded.
* Check trap exist — Check current loading_zone exist.
* Check hole is avialable — Checl loading hole is not busy.
"""
function isallowed_load(qdc::QCCDevControl, loading_zone::Symbol, t::Time_t)
    _time_check(qdc.t_now, t, :load)
    haskey(qdc.loadingZones, loading_zone) || opError("Loading zone with id $loading_zone doesn't exist.")
    qdc.loadingZones[loading_zone].hole != nothing && opError("Loading hole is busy.")
end

"""
Function `isallowed_linear_transport()` — checks feasibility of `linear_transport`.

# Arguments: See `linear_transport`

# checks
* Check time — Call _time_check function.
* Check OperationTimes - Checks if time model is defined for `linear_transport`
* Check ion_idx - Checks if ion is in the device.
* Check destination_idx - Checks if destination zone is in the device.
* Check ion position - Check if ion's position exists in the device.
* Check ion chain - Checks if the ion is in the correct chain position to leave the device.
* Check ends - Checks if ion position and destination are adjacent.
* Check capacity - Checks if destination zone is not currently full.

"""
function isallowed_linear_transport(qdc           :: QCCDevControl,
                                    t             :: Time_t,
                                    ion_idx       :: Int,
                                    destination_idx      :: Symbol)

  destination, currentPosition = 
    _isallowed_common_linear_junction(qdc, t, ion_idx, destination_idx, :linear_transport)

  chain = nothing
  if currentPosition.end0 == destination.id

    chain = currentPosition.zoneType == :loadingZone ? 
        currentPosition.hole : first(currentPosition.chain)
  elseif currentPosition.end1 == destination.id

    chain = currentPosition.zoneType == :loadingZone ? 
      currentPosition.hole : last(currentPosition.chain)
  else
    opError("Can't do linear transport to a non-adjacent zone.")
  end

  if chain != ion_idx && chain != [ion_idx]
    opError("Ion $ion_idx isn't in the correct position or is not alone in the chain.")
  end
end

function _isallowed_common_linear_junction(qdc :: QCCDevControl, t :: Time_t, ion_idx :: Int,
          destination_idx :: Symbol, operation ::Symbol) ::NTuple{2, Union{GateZone, AuxZone, LoadingZone, Junction, Nothing}}

  _time_check(qdc.t_now, t, operation)

  if ion_idx ∉ keys(qdc.qubits)
    opError("Ion with ID $ion_idx is not in device")
  end
  destination = giveZone(qdc, destination_idx)
  if isnothing(destination)
    opError("Zone with ID $destination_idx is not in device")
  end
  currentPosition = giveZone(qdc, qdc.qubits[ion_idx].position)
  if isnothing(currentPosition)
    opError("Ion with ID $ion_idx is nowhere (?)")
  end

  destinationIsLoadingZone = destination.zoneType == :loadingZone
  if (destinationIsLoadingZone && !isnothing(destination.hole)) ||
    (!destinationIsLoadingZone && !isempty(destination.chain) && 
    sum(length, destination.chain) == destination.capacity)
    opError("Destination zone with ID $destination_idx cannot hold more ions.")
  end

  return (destination, currentPosition)
end

"""
Function `isallowed_junction_transport()` — checks feasibility of `junction_transport`.

# Arguments: See `junction_transport`

# checks
* Check time — Call _time_check function.
* Check OperationTimes - Checks if time model is defined for `junction_transport`
* Check ion_idx - Checks if ion is in the device.
* Check destination_idx - Checks if destination zone is in the device.
* Check ion position - Check if ion's position exists in the device.
* Check ion chain - Checks if the ion is in the correct chain position to leave the device.
* Check ends - Checks if ion position and destination are adjacent (through a junction).
* Check capacity - Checks if destination zone is not currently full.

"""
function isallowed_junction_transport(qdc :: QCCDevControl, t :: Time_t,
                                      ion_idx :: Int, destination_idx :: Symbol)
  destination, currPos = 
    _isallowed_common_linear_junction(qdc, t, ion_idx, destination_idx, :junction_transport)
  
  junction = get(qdc.junctions, currPos.end0, nothing)
  if isnothing(junction)
    junction = get(qdc.junctions, currPos.end1, nothing)
  end

  isnothing(junction) && 
            opError("Current ion's position with ID $(currPos.idi) is not connected to a junction")
  destination.id ∈ junction.ends || 
            opError("Destination $(destination.id) is not connected to junction $(junction.id)")
  
  chain = currPos.zoneType === :loadingZone ? currPos.hole : nothing
  if isnothing(chain)
    chain = junction.id === currPos.end0 ? first(currPos.chain) : last(currPos,chain)
  end

  if chain != ion_idx && chain != [ion_idx]
    opError("Ion $ion_idx isn't in the correct position or is not alone in the chain.")
  end

end
end 