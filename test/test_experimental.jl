module TestExperimental
using Test
using Setfield
using Setfield.Experimental
using Setfield.Experimental: quench, stretch

@testset "quench and stretch" begin
    for _ in 1:100
        lower, upper = sort!(randn(2))
        lower = rand(Bool) ? -Inf : lower
        upper = rand(Bool) ? Inf : upper
        @assert lower < upper
        x = randn()
        y = quench(x, lower, upper)
        x2 = stretch(y, lower, upper)
        @test x ≈ x2
        
        # monotone
        x1, x2 = sort!(randn(2))
        y1 = quench(x1, lower, upper)
        y2 = quench(x2, lower, upper)
        @test y1 < y2
    end
end

@testset "QuenchLens and StretchLens" begin
    for _ in 1:100
        lower, upper = sort!(randn(2))
        l1 = QuenchLens(lower, upper)
        l2 = inv(l1)
        x = randn()
        x2 = randn()
        @test l2 isa StretchLens
        @test lower < get(x, l1) < upper
        @test get(x, l1 ∘ l2) ≈ x
        @test set(x, l1 ∘ l2, x2) ≈ x2
    end
end


end #module
