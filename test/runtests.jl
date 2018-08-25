module TestSetfield

using Test
using Setfield

@testset "Performance" begin
    script = joinpath(@__DIR__, "perf.jl")
    cmd = ```
        $(Base.julia_cmd())
        --color=$(Base.have_color ? "yes" : "no")
        --startup-file=no
        --check-bounds=no
        -O3
        $script
    ```
    @test success(pipeline(cmd; stdout=stdout, stderr=stderr))
end

@testset "core" begin
    include("test_core.jl")
end

@testset "settable" begin
    include("test_settable.jl")
end

@testset "StaticArrays.jl" begin
    include("test_staticarrays.jl")
end

@testset "Kwonly.jl" begin
    include("test_kwonly.jl")
end

@testset "QuickTypes.jl" begin
    include("test_quicktypes.jl")
end


end  # module
