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

struct OpData
    op   :: DataType
    t₀   :: Int64         # start time of op
end






end #^ module Schedule
#EOF
