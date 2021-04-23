include("../utils/testUtils.jl")
using qccdSimulator.QCCDevControl_Types
using qccdSimulator.QCCDevControl

function readJSONOK(path::String)::Bool
    qccd1 = readJSON(path) 
    qccd2 = giveQccDes()
    return checkEqualQCCD(qccd1,qccd2)
end

function QCCDevCtrlOKTest()::Bool
    qccd1 = giveQccCtrl()
    qccd2 = QCCDevCtrl(giveQccDes();simulate=false)
    return checkEqualQCCDevCtrl(qccd1,qccd2)
end

function checkEqualQCCD(qccd1::QCCDevDescription, qccd2::QCCDevDescription):: Bool
    @assert qccd1.adjacency.nodes == qccd2.adjacency.nodes
    traps1 = qccd1.trap.traps
    traps2 = qccd2.trap.traps
    @assert size(traps1) == size(traps2)
    @assert qccd1.trap.capacity == qccd2.trap.capacity
    for (trap1,trap2) in zip(traps1,traps2)
        @assert trap1.id == trap2.id
        @assert trap1.end0 == trap2.end0
        @assert trap1.end1 == trap2.end1
        @assert trap1.gate == trap2.gate
        @assert trap1.loading_zone == trap2.loading_zone
    end
    juns1 = qccd1.junction.junctions
    juns2 = qccd2.junction.junctions
    @assert size(juns1) == size(juns2)
    for (jun1,jun2) in zip(juns1,juns2)
        @assert jun1.id == jun2.id
        @assert jun1.type == jun2.type
    end
    shs1 = qccd1.shuttle.shuttles
    shs2 = qccd2.shuttle.shuttles
    @assert size(shs1) == size(shs2)
    for (sh1,sh2) in zip(shs1,shs2)
        @assert sh1.id == sh2.id
        @assert sh1.end0 == sh2.end0
        @assert sh1.end1 == sh2.end1
    end
    return true
end

function checkEqualQCCDevCtrl(qccdc1::QCCDevCtrl,qccdc2::QCCDevCtrl):: Bool
    @assert qccdc1.t_now == qccdc2.t_now
    @assert qccdc1.max_capacity == qccdc2.max_capacity
    @assert checkEqualQCCD(qccdc1.dev, qccdc2.dev)
    @assert nv(qccdc1.graph) == nv(qccdc2.graph)
    @assert ne(qccdc1.graph) == ne(qccdc2.graph)
    @assert length(qccdc1.traps) == length(qccdc2.traps)
    @assert length(qccdc1.junctions) == length(qccdc2.junctions)
    @assert length(qccdc1.shuttles) == length(qccdc2.shuttles)
    for (key,value) in qccdc1.traps
        @assert haskey(qccdc2.traps, key)
        @assert qccdc2.traps[key].id == value.id
        @assert qccdc2.traps[key].capacity == value.capacity
        @assert qccdc2.traps[key].chain == value.chain
        @assert qccdc2.traps[key].end0.qubit == value.end0.qubit
        @assert qccdc2.traps[key].end0.shuttle == value.end0.shuttle
        @assert qccdc2.traps[key].end1.qubit == value.end1.qubit
        @assert qccdc2.traps[key].end1.shuttle == value.end1.shuttle
        @assert qccdc2.traps[key].gate == value.gate
        @assert qccdc2.traps[key].loading_hole == value.loading_hole
    end
    for (key,value) in qccdc1.shuttles
        @assert haskey(qccdc2.shuttles, key)
        @assert qccdc2.shuttles[key].id == value.id
        @assert qccdc2.shuttles[key].end0 == value.end0
        @assert qccdc2.shuttles[key].end1 == value.end1
    end
    for (key,value) in qccdc1.junctions
        @assert haskey(qccdc2.junctions, key)
        @assert qccdc2.junctions[key].id == value.id
        @assert qccdc2.junctions[key].type == value.type
        for (k,v) in qccdc1.junctions[key].ends
            @assert haskey(qccdc1.junctions[key].ends,k)
            @assert qccdc1.junctions[key].ends[k].qubit == v.qubit
            @assert qccdc1.junctions[key].ends[k].status == v.status
        end
    end
    return true
end

function initTrapTest()
    trapDesc::TrapDesc = giveQccDes().trap
    traps = qccdSimulator.QCCDevControl._initTraps(trapDesc)
    for (key, value) in traps
        @assert key == value.id
        @assert trapDesc.capacity == value.capacity
        aux = filter(x-> Symbol(x.id)==key,trapDesc.traps)
        @assert length(aux) == 1
        @assert isempty(value.chain)
        @assert value.end0.qubit == value.end1.qubit == nothing
        tmp = aux[1].end0 == "" ? nothing : Symbol(aux[1].end0)
        @assert tmp == value.end0.shuttle
        tmp = aux[1].end1 == "" ? nothing : Symbol(aux[1].end1)
        @assert tmp == value.end1.shuttle
    end
    return true
end

function initTrapRepeatedIdTest()
    trapDesc::TrapDesc = giveTrapDescRepeatedId()
    return qccdSimulator.QCCDevControl._initTraps(trapDesc)
end

function checkTrapsTest()
    qdd::QCCDevCtrl = giveQccCtrl()
    qccdSimulator.QCCDevControl._checkTraps(qdd.traps,qdd.shuttles)
    return true
end

function checkTrapsShuttleNotExistTest()
    qdd::QCCDevCtrl = giveQccCtrl()
    traps::Dict{Symbol,Trap} = qccdSimulator.QCCDevControl._initTraps(giveTrapDescNonShuttleId())
    qccdSimulator.QCCDevControl._checkTraps(traps,qdd.shuttles)
    return true
end

function checkTrapsShuttleWrongConnectedTest()
    qdd::QCCDevCtrl = giveQccCtrl()
    traps::Dict{Symbol,Trap} = qccdSimulator.QCCDevControl._initTraps(giveTrapDescWrongConnectedShuttle())
    qccdSimulator.QCCDevControl._checkTraps(traps,qdd.shuttles)
    return true
end

function initJunctionsTest()
    _typeSizes = Dict(:T => 3, :Y => 3, :X => 4)
    shuttles, _junctions = giveShuttlesJunctions(9, ["X", "Y", "T","X", "Y", "T","X", "Y", "T"])
    junctions = qccdSimulator.QCCDevControl._initJunctions(shuttles, _junctions)
    for (k,junction) in junctions
        @assert k == junction.id
        juncType = filter(x-> Symbol(x.id)==k,_junctions)[1].type
        juncType = Symbol(juncType)
        @assert junction.type == juncType
        shuttleIds = keys(junction.ends)
        @assert length(shuttleIds) == _typeSizes[juncType]
        for shuttleId in shuttleIds
            shuttle = filter(x -> Symbol(x.id) == shuttleId, shuttles)[1]
            @assert Symbol(string(shuttle.end0)) == k || Symbol(shuttle.end1) == k
        end
    end
    return true
end

function initJunctionsTestRepId()
    shuttles, _junctions = giveShuttlesJunctions(2, ["T","T"];repJunc = true)
    junctions = qccdSimulator.QCCDevControl._initJunctions(shuttles, _junctions)
end

function initJunctionsTestIsolated()
    shuttles, _junctions = giveShuttlesJunctions(2, ["T","T"];isolatedJunc = true)
    junctions = qccdSimulator.QCCDevControl._initJunctions(shuttles, _junctions)
end

function initJunctionsTestWrongType()
    shuttles, _junctions = giveShuttlesJunctions(2, ["T","T"];wrongJuncType = true)
    junctions = qccdSimulator.QCCDevControl._initJunctions(shuttles, _junctions)
end

function initShuttlesTestRepId()
    shuttles, _ = giveShuttlesJunctions(2, ["T","T"];repShuttle = true)
    shDesc = ShuttleDesc(shuttles)
    qccdSimulator.QCCDevControl._initShuttles(shDesc)
end

function initShuttlesTestInvShuttle()
    qccdSimulator.QCCDevControl._initShuttles(giveShuttles(5;invShuttle=true))
end

function initShuttlesTest()
    _shuttles = giveShuttles(10)
    shuttles = qccdSimulator.QCCDevControl._initShuttles(_shuttles)
    @assert length(_shuttles.shuttles) == length(shuttles)
    for _shuttle in _shuttles.shuttles
        shuttle = shuttles[Symbol(_shuttle.id)]
        @assert _shuttle.end0 == parse(Int,string(shuttle.end0))
        @assert _shuttle.end1 == parse(Int,string(shuttle.end1))
    end
    return true
end

function QCCDevCtrlTest()
    qdd::QCCDevDescription = giveQccDes()
    return QCCDevCtrl(qdd; simulate=false)
end

function checkShuttlesTest()
    adj, shuttles = giveShuttlesAdjacency()
    qccdSimulator.QCCDevControl._checkShuttles(adj, shuttles)
    return true
end

function checkShuttlesTestMissingAdj()
    adj, shuttles = giveShuttlesAdjacency()
    try 
        qccdSimulator.QCCDevControl._checkShuttles(delete!(adj, collect(keys(adj))[1]), shuttles)
    catch e
        @assert e.msg == "Number of elements in adjacency list and number of shuttles don't match"
    end
    return true
end

function checkShuttlesTestMissingShuttle()
    adj, shuttles = giveShuttlesAdjacency()
    try 
        qccdSimulator.QCCDevControl.
                        _checkShuttles(adj, delete!(shuttles, collect(keys(shuttles))[1]))
    catch e
        @assert e.msg == "Number of elements in adjacency list and number of shuttles don't match"
    end
    return true
end

"""Checks all combinations for _checkShuttles check function"""
function checkShuttlesTestModifyConnections()
    adj, shuttles = giveShuttlesAdjacency()
    
    # Tamper a 'random' key in the dictionary
    _adj = deepcopy(adj)
    k = collect(keys(_adj))[1]
    _adj[k*"_"] = _adj[k] 
    delete!(_adj, k) # So there isn't a size mismatch
    try
        qccdSimulator.QCCDevControl._checkShuttles(_adj, shuttles)
    catch e
        @assert startswith(e.msg, "Ends don't correspond to adjacency in shuttle ID")
    end
    _adj = nothing

    # Tamper a random value in the dictionary
    _adj = deepcopy(adj)
    _adj[rand(keys(_adj))][1] = -1 
    try
        qccdSimulator.QCCDevControl._checkShuttles(_adj, shuttles)
    catch e
        @assert startswith(e.msg, "Ends don't correspond to adjacency in shuttle ID")
    end
    _adj = nothing

    # An end0 is going to be wrong
    adj, shuttles = giveShuttlesAdjacency(;faultyEnd0=true)
    try
        qccdSimulator.QCCDevControl._checkShuttles(adj, shuttles)
    catch e
        @assert startswith(e.msg, "Ends don't correspond to adjacency in shuttle ID")
    end

    # An end1 is going to be wrong
    adj, shuttles = giveShuttlesAdjacency(;faultyEnd1=true)
    try
        qccdSimulator.QCCDevControl._checkShuttles(adj, shuttles)
    catch e
        @assert startswith(e.msg, "Ends don't correspond to adjacency in shuttle ID")
    end

    return true
end