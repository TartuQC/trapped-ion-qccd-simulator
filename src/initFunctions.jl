using LightGraphs
using .QCCDevDes_Types
using .QCCDevControl_Types

"""
Creates a graph using an object QCCDevDescription.
Throws ArgumentError if LightGraphs fails to add a node. This will happen
    if there are redundancies in the adjacency list (i.e. repeated edges),
    so maybe is not worth having.
"""
function initGraph(topology::QCCDevDescription)::SimpleGraph{Int64}
    nodesAdjacency::Dict{String,Array{Int64}} = topology.adjacency.nodes
    graph::SimpleGraph{Int64} = SimpleGraph(length(nodesAdjacency))

    for nodes in keys(nodesAdjacency) 
        for node in nodesAdjacency[nodes]
            stat = add_edge!(graph, parse(Int64, nodes), node)
            stat || throw(ArgumentError("Failed adding edge ($nodes,$node) to graph."))
        end
    end
    return graph
end

"""
Creates a dictionary of junctions from JSON objects.
Throws ArgumentError if junction IDs are repeated.
Throws ArgumentError if unsupported junction type is passed.
"""
function _initJunctions(shuttles::Array{ShuttleInfoDesc},
            junctions::Array{JunctionInfoDesc})::Dict{Symbol,Junction}
    res = Dict{Symbol,Junction}()
    for j ∈ junctions
        !haskey(res, Symbol(j.id)) || throw(ArgumentError("Repeated junction ID: $(j.id)."))

        connectedShuttles = filter(x -> x.end0 == j.id || x.end1 == j.id, shuttles)
        isempty(connectedShuttles) && throw(ArgumentError("Junction with ID $(j.id) isolated."))
        junctionEnds = Dict(Symbol(s.id) => JunctionEnd() for s ∈ connectedShuttles)
        res[Symbol(j.id)] = Junction(Symbol(j.id), Symbol(j.type), junctionEnds)
    end
    return res
end

"""
Creates a dictionary of shuttles using a object shuttleDesc
Throws ArgumentError if shuttle ID is repeated.
"""
function _initShuttles(shuttleDesc::ShuttleDesc)::Dict{Symbol,Shuttle}
    shuttles = Dict{Symbol,Shuttle}()
    err = id -> ArgumentError("Repeated Shuttle ID: $id ")

    map(sh -> haskey(shuttles, Symbol(sh.id)) ? throw(err(sh.id)) :
              shuttles[Symbol(sh.id)] = Shuttle(Symbol(sh.id), Symbol(sh.end0), Symbol(sh.end1)),
              shuttleDesc.shuttles)
    return shuttles
end

"""
Creates a dictionary of traps using a object trapDesc.
Throws ArgumentError if trap ID is repeated.
"""
function _initTraps(trapDesc::TrapDesc)::Dict{Symbol,Trap}
    traps = Dict{Symbol,Trap}()
    err = id -> ArgumentError("Repeated Trap ID: $id.")

    map(tr -> haskey(traps, Symbol(tr.id)) ? throw(err(tr.id)) :
              traps[Symbol(tr.id)] = Trap(Symbol(tr.id),trapDesc.capacity,
                                        TrapEnd(Symbol(tr.end0)), TrapEnd(Symbol(tr.end1)),
                                        tr.gate, tr.loading_zone),
              trapDesc.traps)
    return traps
end

"""
Throws error when:
    - Shuttle ends don't correspond to JSON adjacency
    - Throws an error if trapsEnds shuttles don't exists or don't correspond with Shuttle adjacency
"""
function _checkInitErrors(adjacency:: Dict{String, Array{Int64}}, traps::Dict{Symbol,Trap},
                                                        shuttles::Dict{Symbol,Shuttle})

    _checkShuttles(adjacency,shuttles)
    _checkTraps(traps,shuttles)
end

"""
Throws an error if trapsEnds shuttles don't exists or don't correspond with Shuttle adjacency
"""
function _checkTraps(traps::Dict{Symbol,Trap}, shuttles::Dict{Symbol,Shuttle})

    err = trapId-> ArgumentError("Shuttle connected to trap ID $trapId does "*
                                 "not exist or is wrong connected.")

    check = (trEnd,trId) -> trEnd.shuttle isa Nothing || (haskey(shuttles, trEnd.shuttle) && 
                            trId in [shuttles[trEnd.shuttle].end0, shuttles[trEnd.shuttle].end1])

    map(tr-> check(tr.end0,tr.id) && check(tr.end1,tr. id) || throw(err(tr.id))
        ,values(traps))
end

"""
Throws an error if shuttle ends don't correspond JSON adjacency.
"""
function _checkShuttles(adjacency:: Dict{String, Array{Int64}}, shuttles::Dict{Symbol,Shuttle})

    errSh = shuttleId -> ArgumentError("Ends don't correspond to adjacency in shuttle "*
                                        "ID $shuttleId.")
    length(shuttles) == sum(length, values(adjacency)) ||
        throw(ArgumentError(
            "Number of elements in adjacency list and number of shuttles don't match"))
            
    check = sh ->
        (haskey(adjacency,string(sh.end0)) && parse(Int,string(sh.end1)) in adjacency[string(sh.end0)]) ||
        (haskey(adjacency,string(sh.end1)) && parse(Int,string(sh.end0)) in adjacency[string(sh.end1)])

    map(sh ->  check(sh) || throw(errSh(sh.id)), values(shuttles))
end

########################################################################################################

"""
--> DEPRECATED
Creates a dictionary of qubits using a object TrapJSON.
Throws ArgumentError if qubit appears in more than one trap.
"""
function initQubits(trapDesctraps::TrapDesc)::Dict{String,Qubit}
    qubits = Dict{String,Qubit}()
    err = (trapId, qubitPos, qubitId) -> ArgumentError("Repeated Ion ID: $qubitId
                                                        ,in traps $trapId, $qubitPos.")

    for trap in trapDesctraps.traps
        map(q -> haskey(qubits, q) ? 
                 throw(err(trap.id, qubits[q].position, qubits[q].id)) :
                 qubits[q] = Qubit(q, :resting, trap.id, nothing),
                 trap.chain)
    end
    return qubits
end
