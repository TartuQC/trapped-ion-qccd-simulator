module QCCDevControl_Types
export Trap, Junction, Shuttle, Qubit, JunctionEnd, TrapEnd, JunctionType, JunctionEndStatus
export QubitStatus, typesSizes, Time_t, QCCDevControl

using LightGraphs
using ..QCCDevDes_Types

# Possible Qubits Status
const QubitStatus = Set([:inLoadingZone, :inGateZone])

# Possible junction status
const JunctionEndStatus = Set([:free, :blocked])

# Supported junction types with corresponding sizes
const JunctionType = Set([:T, :Y, :X ])
const typesSizes = Dict(:T => 3, :Y => 3, :X => 4)

"""
Type for time inside the qdev, in [change if necessary]   10^{-10}
seconds, i.e., ns/10.  All times are ≥0; negative value of expressions
of this type are errors (and may carry local error information).
"""
const Time_t = Int64

"""
Struct for junction end.
queue: Array of qubits waiting in the junction end (if any) 
status: Status of the junction end, either free (queue is empty) or blocked otherwise
"""
struct JunctionEnd
    qubit::Union{Nothing,Symbol}
    status::Symbol
    JunctionEnd() = new(nothing, :free)
    function JunctionEnd(qubit::Symbol, status::Symbol)
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
id: qubit identifictor 
status: current qubit status
    - moving
    - resting
    - waitingDecongestion
    - gateApplied
position: current qubit position
destination: qubit destination, it could not have any
"""
struct Qubit
    id::Symbol
    status::Symbol
    position::Symbol
    destination::Union{Nothing,Symbol}
    function Qubit(id::Symbol, status::Symbol, position::Symbol,
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
    qubit::Union{Symbol, Nothing}
    shuttle::Union{Symbol, Nothing}
    TrapEnd(shuttle) = shuttle == Symbol("") ? new(nothing, nothing) : new(nothing,shuttle)
    TrapEnd(qubit,shuttle) = shuttle == Symbol("") ? new(qubit,nothing) : new(qubit,shuttle)
end

"""  
Struct for the traps.
id: trap identifier
capacity: maximum qubits in the trap 
chain: Orderer Qbits in the trap (from end0 to end1)
end0 & end1: Trap endings
Throws ArgumentError if length(chain) > capacity
"""
struct Trap
    id::Symbol
    capacity::Int64
    chain::Array{Symbol}
    end0::TrapEnd
    end1::TrapEnd
    gate::Bool
    loading_hole::Tuple{Bool, Union{Symbol, Nothing}}
    Trap(id, capacity, end0, end1, gate, holeBool) =
                        new(id, capacity, [], end0, end1, gate, (holeBool,nothing))
end

struct QCCDevControl
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
    QCCDevControl(dev, max_capacity, traps, junctions, shuttles, graph) = 
            new(dev, max_capacity, 0, traps, junctions, shuttles, graph)
end

end