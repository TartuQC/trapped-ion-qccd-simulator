# src/qccdevcontrol.jl
# Created by Anabel Ovide and Alejandro Villoria, 23 April, 2021
# MIT license
# Sub-module QCCDevCtrl

module QCCDev_Feasible
export load_checks

using ..QCCDevControl_Types

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

"""
Function `isallowed_load()` — checks if given time is correct

# Arguments
* `qdc:: Time_t` — Actual qdc device's time.
* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.

The function throws an error if time is not correct.
"""
function  isallowed_load(loading_zone::Symbol, trap::Trap, max_capacity::Int64)
    # TODO Check loading_hole exist and its not busy
    # TODO Check ion number not exceeds device capacity 

    
end

end