# Architecture Design
# BG's scratchpad

const QubitIdx = Cint

@enum   Gate    begin
    XX
    ZZ
    RXY
    X
    Y
    Z
    RZ
    RX
    RY
    CRX
    CRY
    CRZ
    CX
    CY
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
    axis        ::  Float64
end

mutable struct QCirc
    numQubits   :: Cint
    ops         :: Vector{Operation}
end

function apply_XX(qubit1    ::  QubitIdx,
                  qubit2    ::  QubitIdx,
                  circ      ::  QCirc,
                  angle     ::  Float64)    :: Nothing
    @assert 0 ≤ qubit1 ≤ circ.numQubits-1
    @assert 0 ≤ qubit2 ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, qubit2, XX, angle, 0.0))
    return nothing
end

function apply_ZZ(qubit1    ::  QubitIdx,
                  qubit2    ::  QubitIdx,
                  circ      ::  QCirc,
                  angle     ::  Float64)
    @assert 0 ≤ qubit1 ≤ circ.numQubits-1
    @assert 0 ≤ qubit2 ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, qubit2, ZZ, angle, 0.0))
    return nothing
end

function apply_RXY(qubit1       ::  QubitIdx,
                   qubit2       ::  QubitIdx,
                   circ         ::  QCirc,
                   angle        ::  Float64,
                   axis         ::  Float64)    :: Nothing
    @assert 0 ≤ qubit1 ≤ circ.numQubits-1
    @assert 0 ≤ qubit2 ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, qubit2, RXY, angle, axis))
    return nothing
end

function apply_X(qubit      ::  QubitIdx,
                 circ       ::  QCirc)   :: Nothing
    @assert 0 ≤ qubit ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, -1, X, 0.0, 0.0))
    return nothing
end

function apply_Y(qubit     ::  QubitIdx,
                 circ      ::  QCirc)   :: Nothing
    @assert 0 ≤ qubit ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, -1, Y, 0.0, 0.0))
    return nothing
end

function apply_Z(qubit     ::  QubitIdx,
                 circ      ::  QCirc)   :: Nothing
    @assert 0 ≤ qubit ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, -1, Z, 0.0, 0.0))
    return nothing
end

function apply_RX(qubit     ::  QubitIdx,
                  circ      ::  QCirc,
                  angle     ::  Float64)
    @assert 0 ≤ qubit ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit, -1, RX, angle, 0.0))
    return nothing
end

function apply_RY(qubit     ::  QubitIdx,
                  circ      ::  QCirc,
                  angle     ::  Float64)
    @assert 0 ≤ qubit ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit, -1, RY, angle, 0.0))
    return nothing
end

function apply_RZ(qubit     ::  QubitIdx,
                  circ      ::  QCirc,
                  angle     ::  Float64)
    @assert 0 ≤ qubit ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit, -1, RZ, angle, 0.0))
    return nothing
end

function apply_CRX(qubit1       ::  QubitIdx,
                   qubit2       ::  QubitIdx,
                   circ         ::  QCirc,
                   angle        ::  Float64)    :: Nothing
    @assert 0 ≤ qubit1 ≤ circ.numQubits-1
    @assert 0 ≤ qubit2 ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, qubit2, CRX, angle, 0.0))
    return nothing
end

function apply_CRY(qubit1       ::  QubitIdx,
                   qubit2       ::  QubitIdx,
                   circ         ::  QCirc,
                   angle        ::  Float64)    :: Nothing
    @assert 0 ≤ qubit1 ≤ circ.numQubits-1
    @assert 0 ≤ qubit2 ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, qubit2, CRY, angle, 0.0))
    return nothing
end

function apply_CRZ(qubit1       ::  QubitIdx,
                   qubit2       ::  QubitIdx,
                   circ         ::  QCirc,
                   angle        ::  Float64)    :: Nothing
    @assert 0 ≤ qubit1 ≤ circ.numQubits-1
    @assert 0 ≤ qubit2 ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, qubit2, CRZ, angle, 0.0))
    return nothing
end

function apply_CX(qubit1       ::  QubitIdx,
                  qubit2       ::  QubitIdx,
                  circ         ::  QCirc)    :: Nothing
    @assert 0 ≤ qubit1 ≤ circ.numQubits-1
    @assert 0 ≤ qubit2 ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, qubit2, CX, 0.0, 0.0))
    return nothing
end

function apply_CY(qubit1       ::  QubitIdx,
                  qubit2       ::  QubitIdx,
                  circ         ::  QCirc)    :: Nothing
    @assert 0 ≤ qubit1 ≤ circ.numQubits-1
    @assert 0 ≤ qubit2 ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, qubit2, CY, 0.0, 0.0))
    return nothing
end

function apply_CZ(qubit1       ::  QubitIdx,
                  qubit2       ::  QubitIdx,
                  circ         ::  QCirc)    :: Nothing
    @assert 0 ≤ qubit1 ≤ circ.numQubits-1
    @assert 0 ≤ qubit2 ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, qubit2, CZ, 0.0, 0.0))
    return nothing
end

function apply_H(qubit      ::  QubitIdx,
                 circ       ::  QCirc)   :: Nothing
    @assert 0 ≤ qubit ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, -1, H, 0.0, 0.0))
    return nothing
end

function apply_S(qubit      ::  QubitIdx,
                 circ       ::  QCirc)   :: Nothing
    @assert 0 ≤ qubit ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, -1, S, 0.0, 0.0))
    return nothing
end

function apply_T(qubit      ::  QubitIdx,
                 circ       ::  QCirc)   :: Nothing
    @assert 0 ≤ qubit ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, -1, T, 0.0, 0.0))
    return nothing
end

function apply_measure(qubit      ::  QubitIdx,
                 circ       ::  QCirc)   :: Nothing
    @assert 0 ≤ qubit ≤ circ.numQubits-1

    push!(circ.ops, Operation(qubit1, -1, measure, 0.0, 0.0))
    return nothing
end