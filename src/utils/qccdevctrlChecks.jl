# src/qccdevcontrol.jl
# Created by Anabel Ovide and Alejandro Villoria, 23 April, 2021
# MIT license
# Sub-module QCCDevCtrl

module QCCDev_Feasible
export load_checks, isallowed_loadingHole_transport

using ..QCCDevControl_Types

struct OperationNotAllowedException <: Exception
  msg ::String
end
"""
Default error message for QCCD operations.
"""
struct OperationNotAllowedException <: Exception
  msg ::String
end

"""
Function `time_check()` — checks if given time is correct

# Arguments
* `qdc:: Time_t` — Actual qdc device's time.
* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.

The function throws an error if time is not correct.
"""
_time_check(t_qdc:: Time_t, t::Time_t) = begin
  t_qdc.t_now ≤ t  || 
    throw(OperationNotAllowedException("Time must be higher than $(t_qdc.t_now)"))
end


function  load_checks()
    # TODO Check loading_hole exist and its not busy
    # TODO Check ion number not exceeds device capacity trampa
    
end

function  isallowed_loadingHole_transport(qdc           :: QCCDevControl,
                                          t             :: Time_t,
                                          ion_idx       :: Int,
                                          trap_idx      :: Symbol       ):: Bool

  ion_idx ∈ keys(qdc.qubits) ||
          throw(OperationNotAllowedException("Ion with ID $ion_idx is not in device"))

  trap_idx ∈ keys(qdc.traps) ||
          throw(OperationNotAllowedException("Trap with ID $ion_idx is not in device"))

  (qdc.qubits[ion_idx].status == :inLoadingZone && 
    qdc.traps[trap_idx].loading_hole[2] == ion_idx) ||
          throw(OperationNotAllowedException("Ion is not in trap's loading zone"))
  
  

end

end