using .QCCDevDes_Types


"""
Function `time_check()` — checks if given time is correct

# Arguments
* `qdc:: QCCDevCtrl` — Actual qdc device.
* `t::Time_t` — time at which the operation commences.  Must be no earlier than the latest time
  given to previous function calls.

The function throws an error if time is not correct.
"""
time_check(qdc:: QCCDevCtrl, t::T_time) = begin
    dc.t_now ≤ t  || throw(ArgumentError("Time must be higher than $(qdc.t_now)"))
end



function  load_checks()
    # Check loading_hole existe y no está ocupado
    # Check numero iones no es mayor a capacidad trampa no ha superado la capacidad maxima del dispositivo
    
end