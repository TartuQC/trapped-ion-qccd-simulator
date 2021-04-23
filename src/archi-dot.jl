# Architecture Design
# DOT's scratchpad

"""
## 3. Schedule data structure

### Place in the software
- created by "Mapping-Shuttling-Scheduling"
- consumed by "Run", where the individual operations for the
  HW/Simu/RE are issued

### Design goal
- Simple!  It's the output of a function that will be adapted by
  researchers.
- Direct construction & manipulation (i.e., not through service
  functions)

### Content
- refers to one instance of QCCDevDescription
- all hw-gates & measurements (on ions) with scheduled times
- all shuttling operations with scheduled times

### Functions
- checkFeasible()
- 



"""
