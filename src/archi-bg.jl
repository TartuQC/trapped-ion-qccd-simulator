# Architecture Design
# BG's scratchpad

const QubitIdx = Cint

@enum   Gate    begin
    X
    Y
    Z
    Rz
    Rx
    Ry
    U
    CU
    CX
    CZ
    H
    S
    T
    Measure
end

struct Operation
    ctrl        ::  QubitIdx
    trg         ::  QubitIdx
    gate        ::  Gate
    param       ::  Float64
end

struct QCirc
    numQubits   :: Cint
    ops         :: Vector{Operation}
end

