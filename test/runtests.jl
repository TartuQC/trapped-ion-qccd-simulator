include("tests/qccdDev.jl")
using qccdSimulator
using Test
using LightGraphs

@testset "Read JSON" begin
    @test readJSONOK("./testFiles/topology.json")
    @test_throws ArgumentError("Input is not a file") readJSON(".")
    @test_throws ArgumentError readJSON("./testFiles/wrongTopology.json")
    @test readTimeJSONOK("./testFiles/times.json")
    @test readTimeJSONfail(["./testFiles/negativeTimes.json",
                                        "testFiles/wrongTimes.json","testFiles/wrongTimes2.json"])
    @test readTimeJSONnoFile()
end

@testset "QCCDevControl initialization" begin
    @test QCCDevCtrlOKTest()
    # @test nv(QCCDevCtrlTest().graph) == 5
    # @test ne(QCCDevCtrlTest().graph) == 6
    @test initJunctionsTest()
    @test initJunctionsTestRepId()
    @test initJunctionsTestIsolated()
    @test initJunctionsTestWrongType()
    @test initAuxGateZonesTestRepId()
    @test initAuxGateZonesTestInvZone()
    @test initAuxGateZonesTestWithNothing()
    @test initAuxZonesTest()
    @test initGateZoneTest()
    @test_throws ArgumentError("Repeated gate zone with ID: 1.") initGateZoneRepeatedIdTest()   
    @test initLoadingZoneTest()
    @test_throws ArgumentError("Repeated loading zone with ID: 1") initLoadingZoneRepeatedIdTest()
    @test checkInitErrorsTest()
    @test checkInitErrorsTestEdgeCases()
end

@testset "Linear transport" begin
    @test isallowedLinearTransportTestTime()
    @test isallowedLinearTransportTestNoIon()
    @test isallowedLinearTransportTestNoZone()
    @test isallowedLinearTransportTestNonAdjacent()
    @test isallowedLinearTransportTestAllGood()
    @test isallowedLinearTransportTestFull()
    @test isallowedLinearTransportTestBlockedEnd0()
    @test isallowedLinearTransportTestBlockedEnd1()
    @test isallowedLinearTransportTestNotBlockedEnd0()
    @test isallowedLinearTransportTestNotBlockedEnd1()
    @test linearTransportTestOK()
    @test linearTransportTest1()
    @test linearTransportTest2()
    @test linearTransportTest3()

end

@testset "Utils" begin
    @test giveZoneTest() 
end

@testset "Time checks" begin
    @test_throws OperationNotAllowedException("Time must be higher than " *
                        "10") time_check_timeFailsTest()
    @test_throws OperationNotAllowedException("Time model for test not " *
                        "defined.") time_check_modelFailsTest()
    @test time_checkOKTest()
end

@testset "Load ions `load()` & `isallowed_load()` & `initQubit()`" begin
    @test initQubitTest()
    @test isallowedLoad_OK()
    @test_throws OperationNotAllowedException("Loading zone with id test doesn't" *
                                    " exist.") isallowedLoad_zoneNotExistTest()
    @test_throws OperationNotAllowedException("Loading hole is " *
                                              "busy.") isallowedLoad_loadingHoleBusyTest()
    @test loadOKTest()
end 

@testset "Swap & isallowed_swap" begin
    @test_throws OperationNotAllowedException("Qubit with id 99" *
                                              " doesn't exist.") isallowedSwap_qubitNotExist()
    @test_throws OperationNotAllowedException("Qubits with ids 1  " *
                                    "and 2 are not in the same zone.") isallowedSwap_qubitNotSameZone()
    @test_throws OperationNotAllowedException("Swap can only be done " * 
                                             "in Gate Zones.") isallowedSwap_qubitNotGateZone()
    @test_throws OperationNotAllowedException("Qubits with ids 1 and 3 are not" *
                                             " adjacents.") isallowedSwap_qubitsNotAdjacents1()
    @test_throws OperationNotAllowedException("Qubits with ids 4 and 6 are not" *
                                             " adjacents.") isallowedSwap_qubitsNotAdjacents2()
    
    @test_throws OperationNotAllowedException("Qubits with ids 3 and 5 are not in the same" *
                                             " chain.") isallowedSwap_qubitsNotSameChain1()
    @test_throws OperationNotAllowedException("Qubits with ids 3 and 4 are not in the same" *
                                             " chain.") isallowedSwap_qubitsNotSameChain2()
    @test isallowedSwap_OK()
    @test swap_OK1()
    @test swap_OK2()
end

@testset "Junction transport" begin
    @test isallowed_junction_transportFail1()
    @test isallowed_junction_transportFail2()
    @test isallowed_junction_transportFail3()
    @test isallowed_junction_transportFail4()
    @test isallowed_junction_transportFail5()
    @test isallowed_junction_transportFail6()
    @test isallowed_junction_transportFail7()
    @test isallowed_junction_transportFail8()
    @test isallowed_junction_transportGood()
    @test isallowed_junction_transportGoodLoad()
    @test junctionTransportTestOK()
    @test junctionTransportTest1()
    @test junctionTransportTest2()
    @test junctionTransportTest3()
    @test junctionTransportTest4()
end
