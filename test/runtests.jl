module TestSetfield

using Setfield
using Base.Test

if Pkg.installed("QuickTypes") != nothing
    @testset "QuickTypes" begin include("test_quicktypes.jl") end
end

@testset "core" begin
    include("test_core.jl")
end

@testset "macrotools" begin
    include("test_macrotools.jl")
end
@testset "settable" begin
    include("test_settable.jl")
end

if Pkg.installed("StaticArrays") != nothing
    @testset "StaticArrays" begin
        include("test_staticarrays.jl")
        include("spaceship.jl")
    end
end

@testset "Kwonly" begin
    include("test_kwonly.jl")
end
end  # module
