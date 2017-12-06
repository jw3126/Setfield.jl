using Setfield
using Base.Test

struct T
    a
    b
end

@testset "@set" begin
    t = T(1,2)
    t_init = t
    @set t.a = 5
    @test t === T(5,2)
    @set t.b = T(1,2)
    @test t === T(5, T(1,2))
    @test_throws ArgumentError @set t.c = 3
    @test t_init === T(1,2)
    
    t2 = T(1, T(2, T(T(4,4),3)))
    t2_init = t2
    @set t2.b.b.a.a = 5
    @test t2 === T(1, T(2, T(T(5, 4), 3)))
    @set t2.b.b = 4
    @test t2 === T(1, T(2, 4))
    @test_throws ArgumentError @set t2.b.c = 3
    @test_throws ArgumentError @set t2.c.a = 3
    @test t2_init === T(1, T(2, T(T(4,4),3)))
end
