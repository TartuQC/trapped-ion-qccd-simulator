module QCCDevControl_Types
export Trap, Junction, Shuttle, Qubit, JunctionEnd, TrapEnd, JunctionType, JunctionEndStatus
export QubitStatus, typesSizes

using LightGraphs

# Possible Qubits Status
const QubitStatus = Set([:inLoadingZone, :inGateZone])

# Possible junction status
const JunctionEndStatus = Set([:free, :blocked])

# Supported junction types with corresponding sizes
const JunctionType = Set([:T, :Y, :X ])
const typesSizes = Dict(:T => 3, :Y => 3, :X => 4)

"""
Struct for junction end.
queue: Array of qubits waiting in the junction end (if any) 
status: Status of the junction end, either free (queue is empty) or blocked otherwise
"""
struct JunctionEnd
    qubit::Union{Nothing,Int}
    status::Symbol
    JunctionEnd() = new(nothing, :free)
    function JunctionEnd(qubit::Int, status::Symbol)
        status in JunctionEndStatus || 
                throw(ArgumentError("Junction status $status not supported"))
        new(qubit, status)
    end
end

"""
Struct for junction.
id: Junction ID.
type: Type of the junction. Each type may define how the junction works differently
ends: Dict with key being the shuttle ID the junction is connected to and value a JunctionEnd
Throws ArgumentError if junction type doesn't match with number of ends.
"""
struct Junction
    id::Symbol 
    type::Symbol
    ends::Dict{Symbol,JunctionEnd}
    function Junction(id::Symbol, type::Symbol, ends::Dict{Symbol,JunctionEnd})
        type in JunctionType || throw(ArgumentError("Junction type $type not supported"))
        if length(ends) != typesSizes[type]
            throw(ArgumentError("Junction with ID $id of type $type has $(length(ends)) ends." *
            " It should have $(typesSizes[type]) ends."))
        end
        return new(id, type, ends)
    end
end

"""  
Struct for the qubits.
id: qubit ID 
status: current qubit status
    - moving
    - resting
    - waitingDecongestion
    - gateApplied
position: current qubit position
destination: qubit destination, it could not have any
"""
struct Qubit
    id::Int
    status::Symbol
    position::Symbol
    destination::Union{Nothing,Symbol}
    function Qubit(id::Int, status::Symbol, position::Symbol,
                                            destination::Union{Nothing,Symbol})
        status in QubitStatus || throw(ArgumentError("Qubit status $status not supported"))
        return new(id, status, position, destination)
    end
end

"""  
Struct for the shuttles.
id: shuttle ID 
end0 & end1: ID of components they are connected to
Throws ArgumentError if 'end0' and 'end1' are the same
"""
struct Shuttle
    id::Symbol
    end0::Symbol
    end1::Symbol
    Shuttle(id, end0, end1) = end0 == end1 ? 
            throw(ArgumentError("In shuttle ID $id \"end0\" and \"end1\" must be different")) : 
            new(id, end0, end1)
end

"""  
Struct for the trap endings.
qubit: qubit id in that ending 
shuttle: shuttle id the ending is connected
"""
struct TrapEnd
    qubit::Union{Int, Nothing}
    shuttle::Union{Symbol, Nothing}
    TrapEnd(shuttle) = shuttle == Symbol("") ? new(nothing, nothing) : new(nothing,shuttle)
    TrapEnd(qubit,shuttle) = shuttle == Symbol("") ? new(qubit,nothing) : new(qubit,shuttle)
end

"""  
Struct for the traps.
id: trap identifier
capacity: maximum qubits in the trap 
chain: Ordered Qubits in the trap (from end0 to end1)
end0 & end1: Trap endings
Throws ArgumentError if length(chain) > capacity
"""
struct Trap
    id::Symbol
    capacity::Int64
    chain::Array{Int}
    end0::TrapEnd
    end1::TrapEnd
    gate::Bool
    loading_hole::Tuple{Bool, Union{Int, Nothing}}
    Trap(id, capacity, end0, end1, gate, holeBool) =
                        new(id, capacity, [], end0, end1, gate, (holeBool,nothing))
end

end