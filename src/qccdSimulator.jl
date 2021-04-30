module qccdSimulator
export readJSON, readTimeJSON

include("./types/description.jl")
include("./types/control.jl")
include("./utils/qccdevctrlChecks.jl")
include("./qccdevcontrol.jl")

using .QCCDevDes_Types
using JSON3

"""
Creates an object QCCDevDescription from JSON.
Throws ArgumentError if input is not a valid file.
"""
function readJSON(path::String)::QCCDevDescription
    if !isfile(path)
        throw(ArgumentError("Input is not a file"))
    end
    # Parsing JSON
    return topology::QCCDevDescription  = try 
        JSON3.read(read(path, String), QCCDevDescription)
    catch err
        throw(ArgumentError(err.msg))
    end
end

"""
Fills OperationTimes global variable from JSON file.
Throws ArgumentError if input is not a valid file.
Throws ArgumentError if there is a negative time value.
Throws ArgumentError if file contents are not of the format Dict{String, Int}.
"""
function readTimeJSON(path ::String)
    if !isfile(path)
        throw(ArgumentError("Input is not a file"))
    end
    # Parsing JSON
    times = try 
        JSON3.read(read(path, String), Dict{Symbol, Int64})
    catch err
        throw(ArgumentError(err.msg))
    end
    isempty(filter(v -> v < 0, collect(values(times)))) ||
        throw(ArgumentError("Time values can't be negative"))

    setOperationTimes(times)
end

end
