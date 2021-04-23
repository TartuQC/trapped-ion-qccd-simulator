module QCCDevDes_Types
export QCCDevDescription, TrapDesc, TrapInfoDesc, ShuttleDesc, ShuttleInfoDesc
export JunctionDesc, JunctionInfoDesc, AdjacencyDesc

using StructTypes

struct TrapInfoDesc
    id:: Int64
    end0:: String
    end1:: String
    gate:: Bool
    loading_zone:: Bool
end

struct TrapDesc
    capacity:: Int64
    traps:: Array{TrapInfoDesc}
end

struct JunctionInfoDesc
    id:: Int64
    type:: String
end

struct JunctionDesc
    junctions :: Array{JunctionInfoDesc}
end

struct  ShuttleInfoDesc
    id:: String
    end0:: Int64
    end1:: Int64
end

struct ShuttleDesc
    shuttles:: Array{ShuttleInfoDesc}
end

struct AdjacencyDesc
    nodes:: Dict{String,Array{Int64}} 
end

struct QCCDevDescription
    adjacency:: AdjacencyDesc
    trap:: TrapDesc
    junction:: JunctionDesc
    shuttle:: ShuttleDesc
end

StructTypes.StructType(::Type{TrapInfoDesc})= StructTypes.Struct()
StructTypes.StructType(::Type{TrapDesc})= StructTypes.Struct()
StructTypes.StructType(::Type{JunctionInfoDesc})= StructTypes.Struct()
StructTypes.StructType(::Type{JunctionDesc})= StructTypes.Struct()
StructTypes.StructType(::Type{ShuttleInfoDesc})= StructTypes.Struct()
StructTypes.StructType(::Type{ShuttleDesc})= StructTypes.Struct()
StructTypes.StructType(::Type{AdjacencyDesc})= StructTypes.Struct()
StructTypes.StructType(::Type{QCCDevDescription})= StructTypes.Struct()

end