module qccdSimulator
export readJSON

include("./types/description.jl")
include("./types/control.jl")
include("./utils/qccdevctrlChecks.jl")
include("./qccdevcontrol.jl")


using .QCCDevDes_Types
using JSON3

"""
Creates an object QCCDevDescription from JSON.
Throws ArgumentError an error if input is not a valid file.
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

end
