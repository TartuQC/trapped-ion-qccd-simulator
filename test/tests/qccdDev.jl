include("../utils/testUtils.jl")
using qccdSimulator.QCCDevControl_Types
using qccdSimulator.QCCDDevControl
using qccdSimulator.QCCDev_Feasible

# ========= JSON tests =========
function readJSONOK(path::String)::Bool
    qccd1 = readJSON(path) 
    qccd2 = giveQccDes()
    return checkEqualQCCD(qccd1,qccd2)
end

function readTimeJSONOK(path ::String)
    readTimeJSON(path)
    @assert OperationTimes[:load] == 5
    @assert OperationTimes[:linear_transport] == 78
    @assert OperationTimes[:junction_transport] == 35
    @assert OperationTimes[:swap] == 2
    @assert OperationTimes[:split] == 55
    return true
end

function readTimeJSONfail(paths ::Array{String})
   errormsg1 = "Time values can't be negative"
   errormsg2 = "invalid JSON"
   errorcount = 0
   
   for path ∈ paths
        try
            readTimeJSON(path)
        catch e
            @assert startswith(e.msg, errormsg1) || startswith(e.msg, errormsg2)
            errorcount += 1
        end
   end
   @assert errorcount == length(paths)
   return true
end

function readTimeJSONnoFile()
    try
        readTimeJSON("foo")
    catch e
        @assert startswith(e.msg, "Input is not a file")
    end
    
    return true
end
# ========= END JSON tests =========


# ========= Device comparison tests =========
function QCCDevCtrlOKTest()::Bool
    qccd1 = giveQccCtrl()
    qccd2 = QCCDevCtrl(giveQccDes())
    return checkEqualQCCDevCtrl(qccd1,qccd2)
end

function checkEqualQCCD(qccd1::QCCDevDescription, qccd2::QCCDevDescription):: Bool
    # Compare gate zones
    gateZones1 = qccd1.gateZone.gateZones
    gateZones2 = qccd2.gateZone.gateZones
    @assert size(gateZones1) == size(gateZones2)
    for (gateZone1,gateZone2) in zip(gateZones1,gateZones2)
        @assert gateZone1.id == gateZone2.id
        @assert gateZone1.end0 == gateZone2.end0
        @assert gateZone1.end1 == gateZone2.end1
        @assert gateZone1.capacity == gateZone2.capacity
    end
    # Compare auxiliary zones
    auxZones1 = qccd1.auxZone.auxZones
    auxZones2 = qccd2.auxZone.auxZones
    @assert size(auxZones1) == size(auxZones2)
    for (auxZone1,auxZone2) in zip(auxZones1,auxZones2)
        @assert auxZone1.id == auxZone2.id
        @assert auxZone1.end0 == auxZone2.end0
        @assert auxZone1.end1 == auxZone2.end1
        @assert auxZone1.capacity == auxZone2.capacity
    end
    # Compare junctions
    juns1 = qccd1.junction.junctions
    juns2 = qccd2.junction.junctions
    @assert size(juns1) == size(juns2)
    for (jun1,jun2) in zip(juns1,juns2)
        @assert jun1.id == jun2.id
        @assert jun1.type == jun2.type
    end
    # Compare loading zones
    loadZones1 = qccd1.loadZone.loadZones
    loadZones2 = qccd2.loadZone.loadZones
    @assert size(loadZones1) == size(loadZones2)
    for (loadZone1,loadZone2) in zip(loadZones1,loadZones2)
        @assert loadZone1.id == loadZone2.id
        @assert loadZone1.end0 == loadZone2.end0
        @assert loadZone1.end1 == loadZone2.end1
    end
    return true
end

function checkEqualQCCDevCtrl(qccdc1::QCCDevControl,qccdc2::QCCDevControl):: Bool
    @assert qccdc1.t_now == qccdc2.t_now
    @assert qccdc1.simulate == qccdc2.simulate
    @assert qccdc1.qnoise_esimate == qccdc2.qnoise_esimate
    @assert checkEqualQCCD(qccdc1.dev, qccdc2.dev)
    @assert length(qccdc1.gateZones) == length(qccdc2.gateZones)
    @assert length(qccdc1.junctions) == length(qccdc2.junctions)
    @assert length(qccdc1.auxZones) == length(qccdc2.auxZones)
    @assert length(qccdc1.loadingZones) == length(qccdc2.loadingZones)
    for (key,value) in qccdc1.gateZones
        @assert haskey(qccdc2.gateZones, key)
        @assert qccdc2.gateZones[key].id == value.id
        @assert qccdc2.gateZones[key].capacity == value.capacity
        @assert qccdc2.gateZones[key].chain == value.chain
        @assert qccdc2.gateZones[key].end0 == value.end0
        @assert qccdc2.gateZones[key].end1 == value.end1
    end
    for (key,value) in qccdc1.auxZones
        @assert haskey(qccdc2.auxZones, key)
        @assert qccdc2.auxZones[key].id == value.id
        @assert qccdc2.auxZones[key].capacity == value.capacity
        @assert qccdc2.auxZones[key].chain == value.chain
        @assert qccdc2.auxZones[key].end0 == value.end0
        @assert qccdc2.auxZones[key].end1 == value.end1
    end
    for (key,value) in qccdc1.loadingZones
        @assert haskey(qccdc2.loadingZones, key)
        @assert qccdc2.loadingZones[key].id == value.id
        @assert qccdc2.loadingZones[key].end0 == value.end0
        @assert qccdc2.loadingZones[key].end1 == value.end1
        @assert qccdc2.loadingZones[key].hole == value.hole == nothing
    end
    for (key,value) in qccdc1.junctions
        @assert haskey(qccdc2.junctions, key)
        @assert qccdc2.junctions[key].id == value.id
        @assert qccdc2.junctions[key].ends == value.ends
        @assert qccdc2.junctions[key].type == value.type
    end
    return true
end

function QCCDevCtrlTest()
    qdd::QCCDevDescription = giveQccDes()
    return QCCDevCtrl(qdd)
end
# ========= END Device comparison tests =========


# ========= Junction tests =========
function initJunctionsTest()
    nJunctions = rand(5:30)
    juncTypes = [string(type) for type ∈ JunctionType]
    zones, _junctions = giveZonesJunctions(nJunctions, rand(juncTypes, nJunctions))
    #Convert the generic zones to Gate, auxiliary, and loading zones.
    gateZones = ZoneInfoDesc[]
    auxZones = ZoneInfoDesc[]
    loadZones = LoadZoneInfoDesc[]
    for zone ∈ zones
        r = rand()
        if 0 ≤ r ≤ 0.33
            push!(gateZones, zone)
        elseif 0.33 < r ≤ 0.66
            push!(auxZones, zone)
        else
            load = LoadZoneInfoDesc(zone.id,zone.end0,zone.end1)
            push!(loadZones, load)
        end
    end

    junctions = qccdSimulator.QCCDDevControl._initJunctions(gateZones,
                                            auxZones, loadZones, _junctions)
    for (k,junction) in junctions
        @assert k == junction.id
        juncType = filter(x-> Symbol(x.id)==k,_junctions)[1].type #[1] : get first and only element
        juncType = Symbol(juncType)
        @assert junction.type == juncType
        @assert junction.zoneType == :junction
        @assert length(junction.ends) == typesSizes[juncType]
        for zoneId in junction.ends
            zone = filter(x -> Symbol(x.id) == zoneId, zones)[1] #[1] : get first and only element
            @assert Symbol(zone.end0) == k || Symbol(zone.end1) == k
        end
    end
    return true
end

function initJunctionsTestRepId()
    zones, _junctions = giveZonesJunctions(2, ["T","T"];repJunc = true)
    try
        qccdSimulator.QCCDDevControl._initJunctions(zones, nothing, nothing, _junctions)
    catch e
        @assert startswith(e.msg, "Repeated junction ID")
        return true
    end
    return false
end



function initJunctionsTestIsolated()
    zones, _junctions = giveZonesJunctions(2, ["T","T"];isolatedJunc = true)
    try
        qccdSimulator.QCCDDevControl._initJunctions(nothing, zones, nothing, _junctions)
    catch e
        @assert endswith(e.msg, "is not connected to anything.")
        return true
    end
    return false
end

function initJunctionsTestWrongType()
    zones, _junctions = giveZonesJunctions(2, ["T","T"];wrongJuncType = true)
    loadZones = LoadZoneInfoDesc[]
    for zone ∈ zones
        load = LoadZoneInfoDesc(zone.id,zone.end0,zone.end1)
        push!(loadZones, load)
    end
    try
        qccdSimulator.QCCDDevControl._initJunctions(nothing,nothing,loadZones, _junctions)
    catch e
        @assert(e.msg == "Junction with ID 1 of type T has 2 ends. It should have 3 ends.")
        return true
    end
    return false
end
# ========= END Junction tests =========

# ========= Adjacency tests  =========
function initAdjacencyTest()
    device ::QCCDevDescription = giveQccDes()
    adjacency = qccdSimulator.QCCDDevControl._initAdjacency(device)

    @show adjacency

    for (key, value) in adjacency
        auxGate = filter(x-> Symbol(x.id)==key, device.gateZone.gateZones)
        auxLoad = filter(x-> Symbol(x.id)==key, device.loadZone.loadZones)
        auxAux = filter(x-> Symbol(x.id)==key, device.auxZone.auxZones)
        if !isempty(auxGate)
            @assert sort(value) == sort([auxGate[0].end0, auxGate[0].end1])
        elseif !isempty(auxLoad)
            @assert sort(value) == sort([auxLoad[0].end0, auxLoad[0].end1])
        elseif !isempty(auxAux)
            @assert sort(value) == sort([auxAux[0].end0, auxAux[0].end1])
        end
    end
end


# ========= END Adjacency tests  =========

# ========= Loading zones tests =========
function initLoadingZoneTest()
    loadZoneDesc::LoadZoneDesc = giveQccDes().loadZone
    loadZones = qccdSimulator.QCCDDevControl._initLoadingZones(loadZoneDesc)
    for (key, value) in loadZones
        @assert key == value.id
        aux = filter(x-> Symbol(x.id)==key, loadZoneDesc.loadZones)
        @assert length(aux) == 1
        aux = aux[1]
        tmp = aux.end0 == "" ? nothing : Symbol(aux.end0)
        @assert tmp == value.end0
        tmp = aux.end1 == "" ? nothing : Symbol(aux.end1)
        @assert tmp == value.end1
        @assert value.zoneType == :loadingZone
    end
    return true
end

function initLoadingZoneRepeatedIdTest()
    loadZoneDesc::LoadZoneDesc = giveLoadZoneDescRepeatedId()
    return qccdSimulator.QCCDDevControl._initLoadingZones(loadZoneDesc)
end
# ========= END Loading zones tests =========

# ========= Auxiliary and Gate zones tests =========
function initGateZoneTest()
    gateZoneDesc::GateZoneDesc = giveQccDes().gateZone
    gateZones = qccdSimulator.QCCDDevControl._initGateZone(gateZoneDesc)
    for (key, value) in gateZones
        @assert key == value.id
        aux = filter(x-> Symbol(x.id)==key, gateZoneDesc.gateZones)
        @assert length(aux) == 1
        aux = aux[1]
        @assert aux.capacity == value.capacity
        @assert isempty(value.chain) 
        tmp = aux.end0 == "" ? nothing : Symbol(aux.end0)
        @assert tmp == value.end0
        tmp = aux.end1 == "" ? nothing : Symbol(aux.end1)
        @assert tmp == value.end1
        @assert value.zoneType == :gateZone
    end
    return true
end

function initGateZoneRepeatedIdTest()
    gateZoneDesc::GateZoneDesc = giveGateZoneDescRepeatedId()
    return qccdSimulator.QCCDDevControl._initGateZone(gateZoneDesc)
end

function checkInitErrorsTest()
    qdd::QCCDevControl = giveQccCtrl()
    qccdSimulator.QCCDDevControl._checkInitErrors(qdd.junctions,qdd.auxZones,
                                                 qdd.gateZones, qdd.loadingZones)
    return true
end

function initAuxGateZonesTestRepId()
    zones, _ = giveZonesJunctions(2, ["T","T"];repZone = true)
    auxDesc = AuxZoneDesc(zones)
    try
        qccdSimulator.QCCDDevControl._initAuxZones(auxDesc)
    catch e
        @assert startswith(e.msg, "Repeated")
    end
    gateDesc = GateZoneDesc(zones)
    try
        qccdSimulator.QCCDDevControl._initGateZone(gateDesc)
    catch e
        @assert startswith(e.msg, "Repeated")
    end
    return true
end

function initAuxGateZonesTestInvZone()
    try
        qccdSimulator.QCCDDevControl._initAuxZones(AuxZoneDesc(giveZoneInfo(rand(5:10);invZone=true)))
    catch e
        @assert endswith(e.msg, "\"end0\" and \"end1\" must be different")
    end
    try
        qccdSimulator.QCCDDevControl._initGateZone(GateZoneDesc(giveZoneInfo(rand(5:10);invZone=true)))
    catch e
        @assert endswith(e.msg, "\"end0\" and \"end1\" must be different")
    end
    return true
end

function initAuxGateZonesTestWithNothing()
    zones = giveZoneInfo(rand(5:10);giveNothing=true)
    qccdSimulator.QCCDDevControl._initAuxZones(AuxZoneDesc(zones))
    qccdSimulator.QCCDDevControl._initGateZone(GateZoneDesc(zones))
    return true
end

function initAuxZonesTest()
    _auxZones = AuxZoneDesc(giveZoneInfo(rand(10:15)))
    auxZones = qccdSimulator.QCCDDevControl._initAuxZones(_auxZones)
    @assert length(_auxZones.auxZones) == length(auxZones)
    for _auxZone in _auxZones.auxZones
        auxZone = auxZones[Symbol(_auxZone.id)]
        @assert _auxZone.end0 == string(auxZone.end0)
        @assert _auxZone.end1 == string(auxZone.end1)
        @assert _auxZone.capacity == auxZone.capacity
        @assert auxZone.zoneType == :auxZone
    end
    return true
end

# ========= END Auxiliary and Gate zones tests =========

# ========= Init functions check tests =========
function checkInitErrorsTest()
    qdd::QCCDevControl = giveQccCtrl()
    qccdSimulator.QCCDDevControl._checkInitErrors(qdd.junctions,qdd.auxZones,
                                                 qdd.gateZones, qdd.loadingZones)
    return true
end

"""
This function checks the edge cases of __auxCheck.
It repeats the same errors for aux, gate, and loading zones.
"""
function checkInitErrorsTestEdgeCases()
    qdd::QCCDevControl = giveQccCtrl()
    
    #Aux zone with 'nothing' in both ends should throw error:
    _qdd = deepcopy(qdd)
    k = rand(keys(_qdd.auxZones))
    _qdd.auxZones[k] = AuxZone(k,_qdd.auxZones[k].capacity,nothing,nothing)
    try
        qccdSimulator.QCCDDevControl._checkInitErrors(_qdd.junctions,_qdd.auxZones,
                                                 _qdd.gateZones, _qdd.loadingZones)
    catch e
        @assert endswith(e.msg, "Element cannot be isolated")
    end
    _qdd = deepcopy(qdd)

    # Randomly pick aux zones (by keys) and change their end0 or end1 to be nonsense.
    # This should throw error too.
    for k ∈ rand(keys(_qdd.auxZones), min(length(keys(_qdd.auxZones)), rand(1:10)))
        _qdd = deepcopy(qdd)
    
        if !isnothing(_qdd.auxZones[k].end0)
            _qdd.auxZones[k] = AuxZone(k,_qdd.auxZones[k].capacity,:nonsense,_qdd.auxZones[k].end1)
        else
            _qdd.auxZones[k] = AuxZone(k,_qdd.auxZones[k].capacity,_qdd.auxZones[k].end0,:nonsense)
        end
        try
            qccdSimulator.QCCDDevControl._checkInitErrors(_qdd.junctions,_qdd.auxZones,
                                                 _qdd.gateZones, _qdd.loadingZones)
        catch e
            @assert endswith(e.msg, "is wrong connected.")
        end
    end

    #Gate zone with 'nothing' in both ends should throw error:
    _qdd = deepcopy(qdd)
    k = rand(keys(_qdd.gateZones))
    _qdd.gateZones[k] = GateZone(k,_qdd.gateZones[k].capacity,nothing,nothing)
    try
        qccdSimulator.QCCDDevControl._checkInitErrors(_qdd.junctions,_qdd.auxZones,
                                                 _qdd.gateZones, _qdd.loadingZones)
    catch e
        @assert endswith(e.msg, "Element cannot be isolated")
    end
    _qdd = deepcopy(qdd)

    # Randomly pick gate zones (by keys) and change their end0 or end1 to be nonsense.
    # This should throw error too.
    for k ∈ rand(keys(_qdd.gateZones), min(length(keys(_qdd.gateZones)), rand(1:10)))
        _qdd = deepcopy(qdd)
    
        if !isnothing(_qdd.gateZones[k].end0)
            _qdd.gateZones[k] = GateZone(k,_qdd.gateZones[k].capacity,:nonsense,_qdd.gateZones[k].end1)
        else
            _qdd.gateZones[k] = GateZone(k,_qdd.gateZones[k].capacity,_qdd.gateZones[k].end0,:nonsense)
        end
        try
            qccdSimulator.QCCDDevControl._checkInitErrors(_qdd.junctions,_qdd.auxZones,
                                                 _qdd.gateZones, _qdd.loadingZones)
        catch e
            @assert endswith(e.msg, "is wrong connected.")
        end
    end

    #Load zone with 'nothing' in both ends should throw error:
    _qdd = deepcopy(qdd)
    k = rand(keys(_qdd.loadingZones))
    _qdd.loadingZones[k] = LoadingZone(k,nothing,nothing)
    try
        qccdSimulator.QCCDDevControl._checkInitErrors(_qdd.junctions,_qdd.auxZones,
                                                 _qdd.gateZones, _qdd.loadingZones)
    catch e
        @assert endswith(e.msg, "Element cannot be isolated")
    end
    _qdd = deepcopy(qdd)

    # Randomly pick load zones (by keys) and change their end0 or end1 to be nonsense.
    # This should throw error too.
    for k ∈ rand(keys(_qdd.loadingZones), min(length(keys(_qdd.loadingZones)), rand(1:10)))
        _qdd = deepcopy(qdd)
    
        if !isnothing(_qdd.loadingZones[k].end0)
            _qdd.loadingZones[k] = LoadingZone(k,:nonsense,_qdd.loadingZones[k].end1)
        else
            _qdd.loadingZones[k] = LoadingZone(k,_qdd.gateZones[k].end0,:nonsense)
        end
        try
            qccdSimulator.QCCDDevControl._checkInitErrors(_qdd.junctions,_qdd.auxZones,
                                                 _qdd.gateZones, _qdd.loadingZones)
        catch e
            @assert endswith(e.msg, "is wrong connected.")
        end
    end
    return true
end
# ========= END Init functions check tests =========


# ========= linear_transport tests =========
function linearTransportTestOK()
    qdd::QCCDevControl = giveQccCtrl()
    qdd.qubits[1] = Qubit(1,Symbol(8))
    qdd.loadingZones[Symbol(8)].hole = 1

    t = qccdSimulator.QCCDDevControl.linear_transport(qdd, 10, 1, Symbol(3))
    @assert OperationTimes[:linear_transport] == 78
    @assert t == 88
    @assert qdd.t_now == 88
    @assert qdd.qubits[1].position === Symbol(3)
    @assert isnothing(qdd.loadingZones[Symbol(8)].hole)
    @assert qdd.gateZones[Symbol(3)].chain == [[1]]
    return true
end

function linearTransportTest1()
    qdd::QCCDevControl = giveQccCtrl()
    qdd.qubits[1] = Qubit(1,Symbol(3))
    qdd.qubits[1].status = :inGateZone
    qdd.qubits[1].destination = Symbol(7)

    append!(qdd.gateZones[Symbol(3)].chain, [[1],[2]])
    append!(qdd.auxZones[Symbol(7)].chain, [[3]])
    qccdSimulator.QCCDDevControl.linear_transport(qdd, 10, 1, Symbol(7))
    @assert qdd.qubits[1].position === Symbol(7)
    @assert qdd.gateZones[Symbol(3)].chain == [[2]]
    @assert qdd.auxZones[Symbol(7)].chain == [[3],[1]]
    @assert isnothing(qdd.qubits[1].destination)

    return true
end

function linearTransportTest2()
    qdd::QCCDevControl = giveQccCtrl()
    qdd.qubits[1] = Qubit(1,Symbol(3))
    qdd.qubits[1].status = :inGateZone
    qdd.qubits[1].destination = Symbol(7)

    append!(qdd.gateZones[Symbol(3)].chain, [[2],[1]])
    qccdSimulator.QCCDDevControl.linear_transport(qdd, 10, 1, Symbol(8))
    @assert qdd.qubits[1].position === Symbol(8)
    @assert qdd.gateZones[Symbol(3)].chain == [[2]]
    @assert qdd.loadingZones[Symbol(8)].hole == 1
    @assert qdd.qubits[1].destination == Symbol(7)

    return true
end

function linearTransportTest3()
    qdd::QCCDevControl = giveQccCtrl()
    qdd.qubits[1] = Qubit(1,Symbol(7))
    qdd.qubits[1].status = :inGateZone

    append!(qdd.gateZones[Symbol(3)].chain, [[2]])
    append!(qdd.auxZones[Symbol(7)].chain, [[3],[1]])
    qccdSimulator.QCCDDevControl.linear_transport(qdd, 10, 1, Symbol(3))
    @assert qdd.qubits[1].position === Symbol(3)
    @assert qdd.gateZones[Symbol(3)].chain == [[1],[2]]
    @assert qdd.auxZones[Symbol(7)].chain == [[3]]
    @assert isnothing(qdd.qubits[1].destination)

    return true
end

function isallowedLinearTransportTestTime()
    qdd::QCCDevControl = giveQccCtrl()
    try
        isallowed_linear_transport(qdd, qdd.t_now - 5, 1, :a) 
    catch e
        @assert startswith(e.msg,"Time must be higher than")
        return true
    end
    return false
end

function isallowedLinearTransportTestNoIon()
    qdd::QCCDevControl = giveQccCtrl()
    try
        isallowed_linear_transport(qdd, qdd.t_now+1, 1, :a) 
    catch e
        @assert startswith(e.msg,"Ion with ID 1 is not in device")
        return true
    end
    return false
end

function isallowedLinearTransportTestNoZone()
    qdd::QCCDevControl = giveQccCtrl()
    qdd.qubits[1] = Qubit(1,Symbol(8))
    qdd.loadingZones[Symbol(8)].hole = 1
    try
        isallowed_linear_transport(qdd, qdd.t_now+1, 1, :nonsense) 
    catch e
        @assert startswith(e.msg,"Zone with ID nonsense is not in device")
        return true
    end
    return false
end

function isallowedLinearTransportTestNonAdjacent()
    qdd::QCCDevControl = giveQccCtrl()
    qdd.qubits[1] = Qubit(1,Symbol(8))
    qdd.loadingZones[Symbol(8)].hole = 1
    try
        isallowed_linear_transport(qdd, qdd.t_now+1, 1, Symbol(2)) 
    catch e
        @assert startswith(e.msg,"Can't do linear transport to a non-adjacent zone.")
        return true
    end
    return false
end

function isallowedLinearTransportTestAllGood()
    qdd::QCCDevControl = giveQccCtrl()
    qdd.qubits[1] = Qubit(1,Symbol(8))
    qdd.loadingZones[Symbol(8)].hole = 1
    isallowed_linear_transport(qdd, qdd.t_now+1, 1, Symbol(3)) 
    return true
end

function isallowedLinearTransportTestFull()
    dest = Symbol(3)
        
    # "Load" ion
    qdd::QCCDevControl = giveQccCtrl(;alternateDesc=2)
    qdd.qubits[1] = Qubit(1,Symbol(8))
    qdd.loadingZones[Symbol(8)].hole = 1

    # "Fill up" destination
    halvedCapacity = floor(Int64, qdd.gateZones[dest].capacity / 2)
        # Multiple chains to check if reduce works
    push!(qdd.gateZones[dest].chain,
        rand(Int64, halvedCapacity), rand(Int64, halvedCapacity))

    try
        isallowed_linear_transport(qdd, qdd.t_now+1, 1, dest) 
    catch e
        @assert endswith(e.msg,"$dest cannot hold more ions.")
        return true
    end
    return false
end

function isallowedLinearTransportTestBlockedEnd0()
    origin = Symbol(3)
        
    # "Load" ion
    qdd::QCCDevControl = giveQccCtrl(;alternateDesc=2)
    qdd.qubits[1] = Qubit(1,origin)
    halvedCapacity = floor(Int64, qdd.gateZones[origin].capacity / 2)
    push!(qdd.gateZones[origin].chain, rand(2:100, halvedCapacity), [1])
    halvedCapacity -= 1
    push!(qdd.gateZones[origin].chain, rand(2:100, halvedCapacity))

    try
        isallowed_linear_transport(qdd, qdd.t_now+1, 1, Symbol(7)) 
    catch e
        @assert endswith(e.msg,"isn't in the correct position or is not alone in the chain.")
        return true
    end
    return false
end

function isallowedLinearTransportTestBlockedEnd1()
    origin = Symbol(3)
        
    # "Load" ion
    qdd::QCCDevControl = giveQccCtrl(;alternateDesc=2)
    qdd.qubits[1] = Qubit(1,origin)
    halvedCapacity = floor(Int64, qdd.gateZones[origin].capacity / 2)
    push!(qdd.gateZones[origin].chain, rand(2:100, halvedCapacity), [1])
    halvedCapacity -= 1
    push!(qdd.gateZones[origin].chain, rand(2:100, halvedCapacity))

    try
        isallowed_linear_transport(qdd, qdd.t_now+1, 1, Symbol(8)) 
    catch e
        @assert endswith(e.msg,"isn't in the correct position or is not alone in the chain.")
        return true
    end
    return false
end

function isallowedLinearTransportTestNotBlockedEnd0()
    origin = Symbol(3)
        
    # "Load" ion
    qdd::QCCDevControl = giveQccCtrl(;alternateDesc=2)
    qdd.qubits[1] = Qubit(1,origin)
    halvedCapacity = floor(Int64, qdd.gateZones[origin].capacity / 2)
    push!(qdd.gateZones[origin].chain,[1], rand(2:100, halvedCapacity))
    halvedCapacity -= 1
    push!(qdd.gateZones[origin].chain, rand(2:100, halvedCapacity))
    isallowed_linear_transport(qdd, qdd.t_now+1, 1, Symbol(7)) 
    return true
end

function isallowedLinearTransportTestNotBlockedEnd1()
    origin = Symbol(3)
        
    # "Load" ion
    qdd::QCCDevControl = giveQccCtrl(;alternateDesc=2)
    qdd.qubits[1] = Qubit(1,origin)
    halvedCapacity = floor(Int64, qdd.gateZones[origin].capacity / 2)
    push!(qdd.gateZones[origin].chain, rand(2:100, halvedCapacity))
    halvedCapacity -= 1
    push!(qdd.gateZones[origin].chain, rand(2:100, halvedCapacity), [1])
    isallowed_linear_transport(qdd, qdd.t_now+1, 1, Symbol(8))
    return true
end
# ========= END linear_transport tests =========


# ========= Test Utils test =========
function generateAdjQubitsGZTest()
    for i in 1:100
        gccd = giveQccCtrl()
        nChains = rand(5:5)
        nIons = rand(29:29)
        chain,ion1,ion2 = generateAdjQubitsGZ(gccd, nChains, nIons)
        @assert 1 <= chain <= nChains
        @assert ion1+1 == ion2 || ion1-1 == ion2
        @assert nChains == length(gccd.gateZones[Symbol(1)].chain)
        @assert chain <= length(gccd.gateZones[Symbol(1)].chain)
        for i in 1:nChains
            @assert nIons == length(gccd.gateZones[Symbol(1)].chain[i])
        end
        @assert ion1 in gccd.gateZones[Symbol(1)].chain[chain]
        @assert ion2 in gccd.gateZones[Symbol(1)].chain[chain]
    end
    return true
end

function giveZoneTest()
    qdd::QCCDevControl = giveQccCtrl()
    
    zone = giveZone(qdd, :nonsense)
    @assert isnothing(zone)

    k = rand(keys(qdd.gateZones))
    zone = giveZone(qdd, k)
    @assert zone === qdd.gateZones[k]

    k = rand(keys(qdd.junctions))
    zone = giveZone(qdd, k)
    @assert zone === qdd.junctions[k]

    k = rand(keys(qdd.auxZones))
    zone = giveZone(qdd, k)
    @assert zone === qdd.auxZones[k]

    k = rand(keys(qdd.loadingZones))
    zone = giveZone(qdd, k)
    @assert zone === qdd.loadingZones[k]

    return true
end
# ========= END Test Utils test =========

# ========= _time_check functiong test =========
time_check_timeFailsTest() = qccdSimulator.QCCDev_Feasible._time_check( 10, 9, :load)
time_check_modelFailsTest() = qccdSimulator.QCCDev_Feasible._time_check( 10, 12, :test)
time_checkOKTest() = qccdSimulator.QCCDev_Feasible._time_check( 10, 12, :load)
# ========= _time_check functiong test =========

# ========= load functiong test =========
function initQubitTest()
    for i in 1:25
        qubit1 = Qubit(i,:test)
        qubit2 = qccdSimulator.QCCDDevControl.initQubit(:test)
        @assert qubit1.id == qubit2.id == i
        @assert qubit1.status == qubit2.status == :inLoadingZone
        @assert qubit1.position == qubit2.position == :test
        @assert qubit1.destination == qubit2.destination == nothing
    end
    return true
end

function isallowedLoad_zoneNotExistTest()
    qccd = giveQccCtrl()
    isallowed_load(qccd,:test,4)
    return true
end

function isallowedLoad_loadingHoleBusyTest()
    qccd = giveQccCtrl()
    qccd.loadingZones[Symbol(8)].hole = 3
    isallowed_load(qccd,Symbol(8),4)
    return true
end

function isallowedLoad_OK()
    qccd = giveQccCtrl()
    isallowed_load(qccd,Symbol(8),4)
    return true
end

function loadOKTest()
    qccd = giveQccCtrl()
    tmp = qccdSimulator.QCCDDevControl.load(qccd,2,Symbol(8))
    @assert tmp.new_ion_idx == qccdSimulator.QCCDDevControl.NIONS
    @assert tmp.t₀ == 7
    @assert haskey(qccd.qubits, tmp.new_ion_idx)
    @assert qccd.qubits[tmp.new_ion_idx].position == Symbol(8)
    @assert qccd.qubits[tmp.new_ion_idx].destination == nothing
    return true
end
# ========= END load functiong test =========

# ========= swap function test =========
function isallowedSwap_qubitNotExist()
    qccd = giveQccCtrl()
    isallowed_swap_split(qccd, 99, 1, 10)
end

function isallowedSwap_qubitNotSameZone()
    qccd = giveQccCtrl()
    ion1 = giveQubit(Symbol(1),1)
    ion2 = giveQubit(Symbol(2),2)
    qccd.qubits[ion1.id] = deepcopy(ion1)
    qccd.qubits[ion2.id] = deepcopy(ion2)
    push!(qccd.gateZones[Symbol(1)].chain, [ion1.id])
    push!(qccd.gateZones[Symbol(2)].chain, [ion2.id])
    isallowed_swap_split(qccd, ion1.id, ion2.id, 10)
end

function isallowedSwap_qubitNotGateZone()
    qccd = giveQccCtrl()
    ion1 = giveQubit(Symbol(4),1)
    ion2 = giveQubit(Symbol(4),2)
    qccd.qubits[ion1.id] = deepcopy(ion1)
    qccd.qubits[ion2.id] = deepcopy(ion2)
    push!(qccd.auxZones[Symbol(4)].chain, [ion1.id])
    push!(qccd.auxZones[Symbol(4)].chain[1], ion2.id)
    isallowed_swap_split(qccd, ion1.id, ion2.id, 10)
end

function isallowedSwap_qubitsNotAdjacents1()
    qccd = giveQccCtrl()
    ion1 = giveQubit(Symbol(1),1)
    ion2 = giveQubit(Symbol(1),2)
    ion3 = giveQubit(Symbol(1),3)
    qccd.qubits[ion1.id] = deepcopy(ion1)
    qccd.qubits[ion2.id] = deepcopy(ion2)
    qccd.qubits[ion3.id] = deepcopy(ion3)
    push!(qccd.gateZones[Symbol(1)].chain, [ion1.id])
    push!(qccd.gateZones[Symbol(1)].chain[1], ion2.id)
    push!(qccd.gateZones[Symbol(1)].chain[1], ion3.id)
    isallowed_swap_split(qccd, ion1.id, ion3.id, 10)
end

function isallowedSwap_qubitsNotAdjacents2()
    qccd = giveQccCtrl()
    ion1 = giveQubit(Symbol(1),1)
    ion2 = giveQubit(Symbol(1),2)
    ion3 = giveQubit(Symbol(1),3)
    ion4 = giveQubit(Symbol(1),4)
    ion5 = giveQubit(Symbol(1),5)
    ion6 = giveQubit(Symbol(1),6)
    qccd.qubits[ion1.id] = deepcopy(ion1)
    qccd.qubits[ion2.id] = deepcopy(ion2)
    qccd.qubits[ion3.id] = deepcopy(ion3)
    qccd.qubits[ion4.id] = deepcopy(ion4)
    qccd.qubits[ion5.id] = deepcopy(ion5)
    qccd.qubits[ion6.id] = deepcopy(ion6)
    push!(qccd.gateZones[Symbol(1)].chain, [ion1.id])
    push!(qccd.gateZones[Symbol(1)].chain[1], ion2.id)
    push!(qccd.gateZones[Symbol(1)].chain[1], ion3.id)
    push!(qccd.gateZones[Symbol(1)].chain, [ion4.id])
    push!(qccd.gateZones[Symbol(1)].chain[2], ion5.id)
    push!(qccd.gateZones[Symbol(1)].chain[2], ion6.id)
    isallowed_swap_split(qccd, ion4.id, ion6.id, 10)
end

function isallowedSwap_OK()
    qccd = giveQccCtrl()
    ion1 = giveQubit(Symbol(1),1)
    ion2 = giveQubit(Symbol(1),2)
    ion3 = giveQubit(Symbol(1),3)
    qccd.qubits[ion1.id] = deepcopy(ion1)
    qccd.qubits[ion2.id] = deepcopy(ion2)
    qccd.qubits[ion3.id] = deepcopy(ion3)
    push!(qccd.gateZones[Symbol(1)].chain, [ion1.id])
    push!(qccd.gateZones[Symbol(1)].chain[1], ion2.id)
    push!(qccd.gateZones[Symbol(1)].chain[1], ion3.id)
    isallowed_swap_split(qccd, ion2.id, ion3.id, 10)
end

function swap_OK1()
    qccd = giveQccCtrl()
    ion1 = giveQubit(Symbol(1),1)
    ion2 = giveQubit(Symbol(1),2)
    ion3 = giveQubit(Symbol(1),3)
    qccd.qubits[ion1.id] = deepcopy(ion1)
    qccd.qubits[ion2.id] = deepcopy(ion2)
    qccd.qubits[ion3.id] = deepcopy(ion3)
    push!(qccd.gateZones[Symbol(1)].chain, [ion1.id])
    push!(qccd.gateZones[Symbol(1)].chain[1], ion2.id)
    push!(qccd.gateZones[Symbol(1)].chain[1], ion3.id)
    @assert qccd.gateZones[Symbol(1)].chain == [[1,2,3]]
    qccdSimulator.QCCDDevControl.swap(qccd, 2, ion2.id,ion3.id)
    @assert qccd.gateZones[Symbol(1)].chain == [[1,3,2]]
    @assert qccd.t_now == 4
    return true
end

function isallowedSwap_qubitsNotSameChain1()
    qccd = giveQccCtrl()
    ion1 = giveQubit(Symbol(1),1)
    ion2 = giveQubit(Symbol(1),2)
    ion3 = giveQubit(Symbol(1),3)
    ion4 = giveQubit(Symbol(1),4)
    ion5 = giveQubit(Symbol(1),5)
    ion6 = giveQubit(Symbol(1),6)
    qccd.qubits[ion1.id] = deepcopy(ion1)
    qccd.qubits[ion2.id] = deepcopy(ion2)
    qccd.qubits[ion3.id] = deepcopy(ion3)
    qccd.qubits[ion4.id] = deepcopy(ion4)
    qccd.qubits[ion5.id] = deepcopy(ion5)
    qccd.qubits[ion6.id] = deepcopy(ion6)
    push!(qccd.gateZones[Symbol(1)].chain, [ion1.id])
    push!(qccd.gateZones[Symbol(1)].chain[1], ion2.id)
    push!(qccd.gateZones[Symbol(1)].chain[1], ion3.id)
    push!(qccd.gateZones[Symbol(1)].chain, [ion4.id])
    push!(qccd.gateZones[Symbol(1)].chain[2], ion5.id)
    push!(qccd.gateZones[Symbol(1)].chain[2], ion6.id)
    isallowed_swap_split(qccd, ion3.id, ion5.id, 10)
end

function isallowedSwap_qubitsNotSameChain2()
    qccd = giveQccCtrl()
    ion1 = giveQubit(Symbol(1),1)
    ion2 = giveQubit(Symbol(1),2)
    ion3 = giveQubit(Symbol(1),3)
    ion4 = giveQubit(Symbol(1),4)
    ion5 = giveQubit(Symbol(1),5)
    ion6 = giveQubit(Symbol(1),6)
    qccd.qubits[ion1.id] = deepcopy(ion1)
    qccd.qubits[ion2.id] = deepcopy(ion2)
    qccd.qubits[ion3.id] = deepcopy(ion3)
    qccd.qubits[ion4.id] = deepcopy(ion4)
    qccd.qubits[ion5.id] = deepcopy(ion5)
    qccd.qubits[ion6.id] = deepcopy(ion6)
    push!(qccd.gateZones[Symbol(1)].chain, [ion1.id])
    push!(qccd.gateZones[Symbol(1)].chain[1], ion2.id)
    push!(qccd.gateZones[Symbol(1)].chain[1], ion3.id)
    push!(qccd.gateZones[Symbol(1)].chain, [ion4.id])
    push!(qccd.gateZones[Symbol(1)].chain[2], ion5.id)
    push!(qccd.gateZones[Symbol(1)].chain[2], ion6.id)
    isallowed_swap_split(qccd, ion3.id, ion4.id, 10)
end

function swap_OK2()
    qccd = giveQccCtrl()
    ion1 = giveQubit(Symbol(1),1)
    ion2 = giveQubit(Symbol(1),2)
    ion3 = giveQubit(Symbol(1),3)
    ion4 = giveQubit(Symbol(1),4)
    ion5 = giveQubit(Symbol(1),5)
    ion6 = giveQubit(Symbol(1),6)
    qccd.qubits[ion1.id] = deepcopy(ion1)
    qccd.qubits[ion2.id] = deepcopy(ion2)
    qccd.qubits[ion3.id] = deepcopy(ion3)
    qccd.qubits[ion4.id] = deepcopy(ion4)
    qccd.qubits[ion5.id] = deepcopy(ion5)
    qccd.qubits[ion6.id] = deepcopy(ion6)
    push!(qccd.gateZones[Symbol(1)].chain, [ion1.id])
    push!(qccd.gateZones[Symbol(1)].chain[1], ion2.id)
    push!(qccd.gateZones[Symbol(1)].chain[1], ion3.id)
    push!(qccd.gateZones[Symbol(1)].chain, [ion4.id])
    push!(qccd.gateZones[Symbol(1)].chain[2], ion5.id)
    push!(qccd.gateZones[Symbol(1)].chain[2], ion6.id)
    @assert qccd.gateZones[Symbol(1)].chain == [[1,2,3],[4,5,6]]
    qccdSimulator.QCCDDevControl.swap(qccd, 2, ion5.id,ion6.id)
    @assert qccd.gateZones[Symbol(1)].chain == [[1,2,3],[4,6,5]]
    @assert qccd.t_now == 4
    return true
end
# ========= END swap function test =========

# ========= Split function test =========
function isallowedSplit_OK()
    for i in 1:100
        qccd = giveQccCtrl()
        nChains = rand(5:5)
        nIons = rand(29:29)
        _,ion1,ion2 = generateAdjQubitsGZ(qccd, nChains, nIons)
        isallowed_swap_split(qccd, ion1, ion2 , 10)
    end
    return true
end

function split_ions_OK()
    index = 1
    qccd = giveQccCtrl()
    ion1 = giveQubit(Symbol(1),rand(1:29))
    qccd.qubits[ion1.id] = deepcopy(ion1)
    push!(qccd.gateZones[Symbol(1)].chain, [ion1.id])
    for i in 1:30
        if i!= ion1.id
            ion = giveQubit(Symbol(1),i)
            qccd.qubits[ion.id] = deepcopy(ion)
            push!(qccd.gateZones[Symbol(1)].chain[1], ion.id)
        end
    end
    for i in 1:29
        ion = rand(1:29)
        qccdSimulator.QCCDDevControl._split_ions(qccd, ion, ion+1)
        @assert length(qccd.gateZones[Symbol(1)].chain) == i + 1
        tmp = rand(1:29)
        while tmp == ion
            tmp = rand(1:29)
        end
        ion = tmp
    end
end
# ========= END Split function test =========

# ========= Junction transport test =========

# Load to Load
function junctionTransportTestOK()
    qdd::QCCDevControl = giveQccCtrl(;alternateDesc = 3)
    qdd.qubits[1] = Qubit(1,Symbol(11))
    qdd.loadingZones[Symbol(11)].hole = 1

    t = qccdSimulator.QCCDDevControl.junction_transport(qdd, 10, 1, Symbol(12))
    @assert OperationTimes[:junction_transport] == 35
    @assert t == 45
    @assert qdd.t_now == 45
    @assert qdd.qubits[1].position === Symbol(12)
    @assert isnothing(qdd.loadingZones[Symbol(11)].hole)
    @assert qdd.loadingZones[Symbol(12)].hole == 1
    return true
end

# Gate to Aux
function junctionTransportTest1()
    qdd::QCCDevControl = giveQccCtrl(;alternateDesc = 4)
    qdd.qubits[1] = Qubit(1,Symbol(13))
    qdd.qubits[1].status = :inGateZone
    qdd.qubits[1].destination = Symbol(12)

    append!(qdd.gateZones[Symbol(13)].chain, [[2],[1]])
    append!(qdd.auxZones[Symbol(12)].chain, [[3]])
    t = qccdSimulator.QCCDDevControl.junction_transport(qdd, 10, 1, Symbol(12))
    @assert OperationTimes[:junction_transport] == 35
    @assert t == 45
    @assert qdd.t_now == 45
    @assert qdd.qubits[1].position === Symbol(12)
    @assert qdd.gateZones[Symbol(13)].chain == [[2]]
    @assert qdd.auxZones[Symbol(12)].chain == [[3], [1]]
    @assert isnothing(qdd.qubits[1].destination)

    return true
end

# Gate to load
function junctionTransportTest2()
    qdd::QCCDevControl = giveQccCtrl(;alternateDesc = 4)
    qdd.qubits[1] = Qubit(1,Symbol(13))
    qdd.qubits[1].status = :inGateZone
    qdd.qubits[1].destination = Symbol(7)

    append!(qdd.gateZones[Symbol(13)].chain, [[2],[1]])
    t = qccdSimulator.QCCDDevControl.junction_transport(qdd, 10, 1, Symbol(11))
    @assert OperationTimes[:junction_transport] == 35
    @assert t == 45
    @assert qdd.t_now == 45
    @assert qdd.qubits[1].position === Symbol(11)
    @assert qdd.gateZones[Symbol(13)].chain == [[2]]
    @assert qdd.loadingZones[Symbol(11)].hole == 1
    @assert qdd.qubits[1].destination == Symbol(7)

    return true
end

# Aux to Gate
function junctionTransportTest3()
    qdd ::QCCDevControl = giveQccCtrl(;alternateDesc = 4)
    qdd.qubits[1] = Qubit(1,Symbol(14))
    qdd.qubits[1].status = :inGateZone

    append!(qdd.gateZones[Symbol(13)].chain, [[2]])
    append!(qdd.auxZones[Symbol(14)].chain, [[1], [3]])
    t = qccdSimulator.QCCDDevControl.junction_transport(qdd, 10, 1, Symbol(13))
    @assert OperationTimes[:junction_transport] == 35
    @assert t == 45
    @assert qdd.t_now == 45
    @assert qdd.qubits[1].position === Symbol(13)
    @assert qdd.gateZones[Symbol(13)].chain == [[2], [1]]
    @assert qdd.auxZones[Symbol(14)].chain == [[3]]

    return true
end

# Aux to Gate
function junctionTransportTest4()
    qdd ::QCCDevControl = giveQccCtrl(;alternateDesc = 4)
    qdd.qubits[1] = Qubit(1,Symbol(14))
    qdd.qubits[1].status = :inGateZone

    append!(qdd.auxZones[Symbol(7)].chain, [[2]])
    append!(qdd.auxZones[Symbol(14)].chain, [[3], [1]])
    t = qccdSimulator.QCCDDevControl.junction_transport(qdd, 10, 1, Symbol(7))
    @assert OperationTimes[:junction_transport] == 35
    @assert t == 45
    @assert qdd.t_now == 45
    @assert qdd.qubits[1].position === Symbol(7)
    @assert qdd.auxZones[Symbol(7)].chain == [[1], [2]]
    @assert qdd.auxZones[Symbol(14)].chain == [[3]]

    return true
end

function isallowed_junction_transportFail1()
    qccd = giveQccCtrl()
    ion = giveQubit(Symbol(1),1)
    qccd.qubits[ion.id] = ion
    try
        isallowed_junction_transport(qccd, 10, 1, Symbol(2)) 
    catch e
        @assert e.msg == "Origin zone with ID 1 and destination zone with ID " *
                            "2 are not connected by a junction"
        return true
    end
    return false
end

function isallowed_junction_transportFail2()
    qccd = giveQccCtrl()
    ion = giveQubit(Symbol(5),1)
    qccd.qubits[ion.id] = ion
    try
        isallowed_junction_transport(qccd, 10, 1, Symbol(1)) 
    catch e
        @assert e.msg == "Origin zone with ID 5 and destination zone with ID " *
                            "1 are not connected by a junction"
        return true
    end
    return false
end

function isallowed_junction_transportFail3()
    qccd = giveQccCtrl()
    origin = Symbol(6)
    ion = giveQubit(origin,1)
    qccd.qubits[ion.id] = ion
    push!(qccd.auxZones[origin].chain, [2])
    push!(qccd.auxZones[origin].chain, [1])
    try
        isallowed_junction_transport(qccd, 10, 1, Symbol(7)) 
    catch e
        @assert e.msg == "Ion 1 isn't in the correct position or is not alone in the chain."
        return true
    end
    return false
end

function isallowed_junction_transportFail4()
    qccd = giveQccCtrl()
    origin = Symbol(6)
    ion = giveQubit(origin,1)
    qccd.qubits[ion.id] = ion
    push!(qccd.auxZones[origin].chain, [1,2])
    try
        isallowed_junction_transport(qccd, 10, 1, Symbol(5)) 
    catch e
        @assert e.msg == "Ion 1 isn't in the correct position or is not alone in the chain."
        return true
    end
    return false
end

function isallowed_junction_transportFail5()
    qccd = giveQccCtrl()
    origin = Symbol(5)
    ion = giveQubit(origin,1)
    qccd.qubits[ion.id] = ion
    push!(qccd.auxZones[origin].chain, [1,2])
    try
        isallowed_junction_transport(qccd, 10, 1, Symbol(6)) 
    catch e
        @assert e.msg == "Ion 1 isn't in the correct position or is not alone in the chain."
        return true
    end
    return false
end

function isallowed_junction_transportFail6()
    qccd = giveQccCtrl()
    origin = Symbol(5)
    ion = giveQubit(origin,1)
    qccd.qubits[ion.id] = ion
    push!(qccd.auxZones[origin].chain, [1])
    push!(qccd.auxZones[origin].chain, [2])
    try
        isallowed_junction_transport(qccd, 10, 1, Symbol(6)) 
    catch e
        @assert e.msg == "Ion 1 isn't in the correct position or is not alone in the chain."
        return true
    end
    return false
end

function isallowed_junction_transportFail7()
    qccd = giveQccCtrl(;alternateDesc = 4)
    origin = Symbol(14)
    ion = giveQubit(origin,1)
    qccd.qubits[ion.id] = ion
    push!(qccd.auxZones[origin].chain, [1])
    push!(qccd.auxZones[origin].chain, [2])
    try
        isallowed_junction_transport(qccd, 10, 1, Symbol(7)) 
    catch e
        @assert e.msg == "Ion 1 isn't in the correct position or is not alone in the chain."
        return true
    end
    return false
end

function isallowed_junction_transportFail8()
    qccd = giveQccCtrl(;alternateDesc = 4)
    origin = Symbol(14)
    ion = giveQubit(origin,1)
    qccd.qubits[ion.id] = ion
    push!(qccd.auxZones[origin].chain, [2])
    push!(qccd.auxZones[origin].chain, [1])
    try
        isallowed_junction_transport(qccd, 10, 1, Symbol(13)) 
    catch e
        @assert e.msg == "Ion 1 isn't in the correct position or is not alone in the chain."
        return true
    end
    return false
end


function isallowed_junction_transportGood()
    qccd = giveQccCtrl()
    origin = Symbol(5)
    ion = giveQubit(origin,1)
    qccd.qubits[ion.id] = ion
    push!(qccd.auxZones[origin].chain, [2])
    push!(qccd.auxZones[origin].chain, [1])
    isallowed_junction_transport(qccd, 10, 1, Symbol(6))

    origin = Symbol(6)
    ion = giveQubit(origin,2)
    qccd.qubits[ion.id] = ion
    push!(qccd.auxZones[origin].chain, [2])
    push!(qccd.auxZones[origin].chain, [1])
    isallowed_junction_transport(qccd, 10, 2, Symbol(7))
    return true
end

function isallowed_junction_transportGoodLoad()
    qccd = giveQccCtrl(;alternateDesc=3)
    origin = Symbol(11)
    ion = giveQubit(origin,1)
    qccd.qubits[ion.id] = ion
    qccd.loadingZones[origin].hole = ion.id
    
    isallowed_junction_transport(qccd, 10, 1, Symbol(12))

    origin = Symbol(13)
    ion = giveQubit(origin,2)
    qccd.qubits[ion.id] = ion
    qccd.loadingZones[origin].hole = ion.id
    isallowed_junction_transport(qccd, 10, 2, Symbol(12))

    origin = Symbol(12)
    ion = giveQubit(origin,3)
    qccd.qubits[ion.id] = ion
    qccd.loadingZones[origin].hole = ion.id
    qccd.loadingZones[Symbol(11)].hole = nothing
    isallowed_junction_transport(qccd, 10, 3, Symbol(11))

    return true
end
# ========= END Junction transport test =========
