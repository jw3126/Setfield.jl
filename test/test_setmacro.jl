module TestSetMacro

module Clone
using Setfield: setmacro, lensmacro

macro lens(ex)
    lensmacro(identity, ex)
end

macro set(ex)
    setmacro(identity, ex)
end

end#module Clone

using Setfield: Setfield
using Test
using .Clone: Clone

using StaticArrays: @SMatrix
using StaticNumbers

@testset "setmacro, lensmacro isolation" begin

    # test that no symbols like `IndexLens` are needed:
    @test Clone.@lens(_                                   ) isa Setfield.Lens
    @test Clone.@lens(_.a                                 ) isa Setfield.Lens
    @test Clone.@lens(_[1]                                ) isa Setfield.Lens
    @test Clone.@lens(first(_)                            ) isa Setfield.Lens
    @test Clone.@lens(_[end]                              ) isa Setfield.Lens
    @test Clone.@lens(_[static(1)]                           ) isa Setfield.Lens
    @test Clone.@lens(_.a[1][end, end-2].b[static(1), static(1)]) isa Setfield.Lens

    @test Setfield.@lens(_.a) === Clone.@lens(_.a)
    @test Setfield.@lens(_.a.b) === Clone.@lens(_.a.b)
    @test Setfield.@lens(_.a.b[1,2]) === Clone.@lens(_.a.b[1,2])

    o = (a=1, b=2)
    @test Clone.@set(o.a = 2) === Setfield.@set(o.a = 2)
    @test Clone.@set(o.a += 2) === Setfield.@set(o.a += 2)

    m = @SMatrix [0 0; 0 0]
    m2 = Clone.@set m[end-1, end] = 1
    @test m2 === @SMatrix [0 1; 0 0]
    m3 = Clone.@set(first(m) = 1)
    @test m3 === @SMatrix[1 0; 0 0]
end

function test_all_inferrable(f, argtypes)
    typed = first(code_typed(f, argtypes))
    code = typed.first
    @test all(T -> !(T isa UnionAll || T === Any), code.slottypes)
end

# Example of macro that caused inference issues before.
macro test_macro(expr)
    quote
        function f($(esc(:x)))
            $(Setfield.setmacro(identity, expr, overwrite=true))
            $(Setfield.setmacro(identity, expr, overwrite=true))
            $(Setfield.setmacro(identity, expr, overwrite=true))
            $(Setfield.setmacro(identity, expr, overwrite=true))
            $(Setfield.setmacro(identity, expr, overwrite=true))
            return $(esc(:x))
        end
    end
end

if VERSION >= v"1.3"
    @testset "setmacro multiple usage" begin
        let f = @test_macro(x[end] = 1)
            test_all_inferrable(f, (Vector{Float64}, ))
        end
    end
end

end#module

