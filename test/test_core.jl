module TestCore
using Test
using Setfield
using Setfield: compose, get_update_op
using ConstructionBase: ConstructionBase
using StaticNumbers: static

struct T
    a
    b
end

struct TT{A,B}
    a::A
    b::B
end

@testset "get_update_op" begin
    @test get_update_op(:(&=)) === :(&)
    @test get_update_op(:(^=)) === :(^)
    @test get_update_op(:(-=)) === :(-)
    @test get_update_op(:(%=)) === :(%)
    @test_throws ArgumentError get_update_op(:(++))
    @test_throws ArgumentError get_update_op(:(<=))
end

@testset "@set!" begin
    a = 1
    @set a = 2
    @test a === 1
    @set! a = 2
    @test a === 2

    t = T(1, T(2,3))
    @set t.b.a = 20
    @test t === T(1, T(2,3))

    @set! t.b.a = 20
    @test t === T(1,T(20,3))

    a = 1
    @set! a += 10
    @test a === 11
    nt = (a=1,)
    @set! nt.a = 5
    @test nt === (a=5,)
end

@testset "@set" begin

    t = T(1, T(2, T(T(4,4),3)))
    s = @set t.b.b.a.a = 5
    @test t === T(1, T(2, T(T(4,4),3)))
    @test s === T(1, T(2, T(T(5, 4), 3)))
    @test_throws ArgumentError @set t.b.b.a.a.a = 3

    t = T(1,2)
    @test T(1, T(1,2)) === @set t.b = T(1,2)
    @test_throws ArgumentError @set t.c = 3

    t = T(T(2,2), 1)
    s = @set t.a.a = 3
    @test s === T(T(3, 2), 1)

    t = T(1, T(2, T(T(4,4),3)))
    s = @set t.b.b = 4
    @test s === T(1, T(2, 4))

    t = T(1,2)
    s = @set t.a += 1
    @test s === T(2,2)

    t = T(1,2)
    s = @set t.b -= 2
    @test s === T(1,0)

    t = T(10, 20)
    s = @set t.a *= 10
    @test s === T(100, 20)

    t = T(2,1)
    s = @set t.a /= 2
    @test s === T(1.0,1)

    t = T(1, 2)
    s = @set t.a <<= 2
    @test s === T(4, 2)

    t = T(8, 2)
    s = @set t.a >>= 2
    @test s === T(2, 2)

    t = T(1, 2)
    s = @set t.a &= 0
    @test s === T(0, 2)

    t = T(1, 2)
    s = @set t.a |= 2
    @test s === T(3, 2)

    t = T((1,2),(3,4))
    @set t.a[1] = 10
    s1 = @set t.a[1] = 10
    @test s1 === T((10,2),(3,4))
    i = 1
    si = @set t.a[i] = 10
    @test s1 === si
    se = @set t.a[end] = 20
    @test se === T((1,20),(3,4))
    se1 = @set t.a[end-1] = 10
    @test s1 === se1

    s1 = @set t.a[static(1)] = 10
    @test s1 === T((10,2),(3,4))
    i = 1
    si = @set t.a[static(i)] = 10
    @test s1 === si

    t = @set T(1,2).a = 2
    @test t === T(2,2)

    t = (1, 2, 3, 4)
    @test (@set t[length(t)] = 40) === (1, 2, 3, 40)
    @test (@set t[length(t) ÷ 2] = 20) === (1, 20, 3, 4)
end


struct UserDefinedLens <: Lens end

struct LensWithTextPlain <: Lens end
Base.show(io::IO, ::MIME"text/plain", ::LensWithTextPlain) =
    print(io, "I define text/plain.")


@testset "show it like you build it " begin
    i = 3
    @testset for item in [
            @lens _.a
            @lens _[1]
            @lens _[:a]
            @lens _["a"]
            @lens _[static(1)]
            @lens _[static(1), static(1 + 1)]
            @lens _.a.b[:c]["d"][2][static(3)]
            @lens _
            @lens first(_)
            @lens last(first(_))
            @lens last(first(_.a))[1]
            UserDefinedLens()
            (@lens _.a) ∘ UserDefinedLens()
            UserDefinedLens() ∘ (@lens _.b)
            (@lens _.a) ∘ UserDefinedLens() ∘ (@lens _.b)
            (@lens _.a) ∘ LensWithTextPlain() ∘ (@lens _.b)
        ]
        buf = IOBuffer()
        show(buf, item)
        item2 = eval(Meta.parse(String(take!(buf))))
        @test item === item2
    end
end

function test_getset_laws(lens, obj, val1, val2)

    # set ∘ get
    val = get(obj, lens)
    @test set(obj, lens, val) == obj

    # get ∘ set
    obj1 = set(obj, lens, val1)
    @test get(obj1, lens) == val1

    # set idempotent
    obj12 = set(obj1, lens, val2)
    obj2 = set(obj, lens, val2)
    @test obj12 == obj2
end

function test_modify_law(f, lens, obj)
    obj_modify = modify(f, obj, lens)
    old_val = get(obj, lens)
    val = f(old_val)
    obj_setfget = set(obj, lens, val)
    @test obj_modify == obj_setfget
end

@testset "lens laws" begin
    obj = T(2, T(T(3,(4,4)), 2))
    i = 2
    for lens ∈ [
            @lens _.a
            @lens _.b
            @lens _.b.a
            @lens _.b.a.b[2]
            @lens _.b.a.b[i]
            @lens _.b.a.b[static(2)]
            @lens _.b.a.b[static(i)]
            @lens _.b.a.b[end]
            @lens _.b.a.b[identity(end) - 1]
            @lens _
        ]
        val1, val2 = randn(2)
        f(x) = (x,x)
        test_getset_laws(lens, obj, val1, val2)
        test_modify_law(f, lens, obj)
    end
end

@testset "equality & hashing" begin
    # singletons (identity and property lens) are egal
    for (l1, l2) ∈ [
        @lens(_) => @lens(_),
        @lens(_.a) => @lens(_.a),
    ]
        @test l1 === l2
        @test l1 == l2
        @test hash(l1) == hash(l2)
    end

    # composite and index lenses are structurally equal
    for (l1, l2) ∈ [
        @lens(_[1]) => @lens(_[1]),
        @lens(_.a[2]) => @lens(_.a[2]),
        @lens(_.a.b[3]) => @lens(_.a.b[3]),
        @lens(_[1:10]) => @lens(_[1:10]),
        @lens(_.a[2:20]) => @lens(_.a[2:20]),
        @lens(_.a.b[3:30]) => @lens(_.a.b[3:30]),
    ]
        @test l1 == l2
        @test hash(l1) == hash(l2)
    end

    # inequality
    for (l1, l2) ∈ [
        @lens(_[1]) => @lens(_[2]),
        @lens(_.a[1]) => @lens(_.a[2]),
        @lens(_.a[1]) => @lens(_.b[1]),
        @lens(_[1:10]) => @lens(_[2:20]),
        @lens(_.a[1:10]) => @lens(_.a[2:20]),
        @lens(_.a[1:10]) => @lens(_.b[1:10]),
    ]
        @test l1 != l2
    end

    # equality with non-equal range types (#165)
    for (l1, l2) ∈ [
        @lens(_[1:10]) => @lens(_[Base.OneTo(10)]),
        @lens(_.a[1:10]) => @lens(_.a[Base.OneTo(10)]),
        @lens(_.a.b[1:10]) => @lens(_.a.b[Base.OneTo(10)]),
        @lens(_.a[Base.StepRange(1, 1, 5)].b[1:10]) => @lens(_.a[1:5].b[Base.OneTo(10)]),
        @lens(_.a.b[1:3]) => @lens(_.a.b[[1, 2, 3]]),
    ]
        @test l1 == l2
        @test hash(l1) == hash(l2)
    end

    # Hash property: equality implies equal hashes, or in other terms:
    # lenses either have equal hashes or are unequal
    # Because collisions can occur theoretically (though unlikely), this is a property test,
    # not a unit test.
    random_lenses = (@lens(_.a[rand(Int)]) for _ in 1:1000)
    @test all((hash(l2) == hash(l1)) || (l1 != l2)
              for (l1, l2) in zip(random_lenses, random_lenses))

    # Lenses should hash differently from the underlying tuples, to avoid confusion.
    # To account for potential collisions, we check that the property holds with high
    # probability.  
    @test count(hash(@lens(_[i])) != hash((i,)) for i = 1:1000) > 900

    # Same for tuples of tuples (√(1000) ≈ 32).
    @test count(hash(@lens(_[i][j])) != hash(((i,), (j,))) for i = 1:32, j = 1:32) > 900
end


@testset "type stability" begin
    o1 = 2
    o22 = 2
    o212 = (4,4)
    o211 = 3
    o21 = TT(o211, o212)
    o2 = TT(o21, o22)
    obj = TT(o1, o2)
    @assert obj === TT(2, TT(TT(3,(4,4)), 2))
    i = 1
    for (lens, val) ∈ [
          ((@lens _.a           ),   o1 ),
          ((@lens _.b           ),   o2 ),
          ((@lens _.b.a         ),   o21),
          ((@lens _.b.a.b[2]    ),   4  ),
          ((@lens _.b.a.b[i+1]  ),   4  ),
          ((@lens _.b.a.b[static(2)]   ),   4  ),
          ((@lens _.b.a.b[static((i+1))]),  4  ),
          ((@lens _.b.a.b[static(2)]   ),   4.0),
          ((@lens _.b.a.b[static((i+1))]),  4.0),
          ((@lens _.b.a.b[end]),     4.0),
          ((@lens _.b.a.b[end÷2+1]), 4.0),
          ((@lens _             ),   obj),
          ((@lens _             ),   :xy),
        ]
        @inferred get(obj, lens)
        @inferred set(obj, lens, val)
        @inferred modify(identity, obj, lens)
    end
end

@testset "IndexLens" begin
    l = @lens _[]
    @test l isa Setfield.IndexLens
    x = randn()
    obj = Ref(x)
    @test get(obj, l) == x

    l = @lens _[][]
    @test l.outer isa Setfield.IndexLens
    @test l.inner isa Setfield.IndexLens
    inner = Ref(x)
    obj = Base.RefValue{typeof(inner)}(inner)
    @test get(obj, l) == x

    obj = (1,2,3)
    l = @lens _[1]
    @test l isa Setfield.IndexLens
    @test get(obj, l) == 1
    @test set(obj, l, 6) == (6,2,3)


    l = @lens _[1:3]
    @test l isa Setfield.IndexLens
    @test get([4,5,6,7], l) == [4,5,6]
end

@testset "DynamicIndexLens" begin
    l = @lens _[end]
    @test l isa Setfield.DynamicIndexLens
    obj = (1,2,3)
    @test get(obj, l) == 3
    @test set(obj, l, true) == (1,2,true)

    l = @lens _[end÷2]
    @test l isa Setfield.DynamicIndexLens
    obj = (1,2,3)
    @test get(obj, l) == 1
    @test set(obj, l, true) == (true,2,3)

    two = 2
    plusone(x) = x + 1
    l = @lens _.a[plusone(end) - two].b
    obj = (a=(1, (a=10, b=20), 3), b=4)
    @test get(obj, l) == 20
    @test set(obj, l, true) == (a=(1, (a=10, b=true), 3), b=4)

    if Setfield.HAS_BEGIN_INDEXING
        # Need to keep this in a separate file since `begin` won't parse
        # on older Julia versions.
        include("dynamiclens_begin.jl")
    end
end

@testset "StaticNumbers" begin
    obj = (1, 2.0, '3')
    l = @lens _[static(1)]
    @test (@inferred get(obj, l)) === 1
    @test (@inferred set(obj, l, 6.0)) === (6.0, 2.0, '3')
    l = @lens _[static(1 + 1)]
    @test (@inferred get(obj, l)) === 2.0
    @test (@inferred set(obj, l, 6)) === (1, 6, '3')
    n = 1
    l = @lens _[static(3n)]
    @test (@inferred get(obj, l)) === '3'
    @test (@inferred set(obj, l, 6)) === (1, 2.0, 6)

    l = @lens _[static(1):static(3)]
    @test get([4,5,6,7], l) == [4,5,6]

    @testset "complex example (sweeper)" begin
        sweeper_with_const = (
            model = (1, 2.0, 3im),
            axis = (@lens _[static(2)]),
        )

        sweeper_with_noconst = @set sweeper_with_const.axis = @lens _[2]

        function f(s)
            a = sum(set(s.model, s.axis, 0))
            for i in 1:10
                a += sum(set(s.model, s.axis, i))
            end
            return a
        end

        @test (@inferred f(sweeper_with_const)) == 66 + 33im
        @test_broken (@inferred f(sweeper_with_noconst)) == 66 + 33im
    end
end

mutable struct M
    a
    b
end

@testset "IdentityLens" begin
    id = @lens _
    @test compose(id, id) === id
    obj1 = M(1,1)
    obj2 = M(2,2)
    @test obj2 === set(obj1, id, obj2)
    la = @lens _.a
    @test compose(id, la) === la
    @test compose(la, id) === la
end

struct ABC{A,B,C}
    a::A
    b::B
    c::C
end

@testset "type change during @set (default constructorof)" begin
    obj = TT(2,3)
    obj2 = @set obj.b = :three
    @test obj2 === TT(2, :three)
end

# https://github.com/tkf/Reconstructables.jl#how-to-use-type-parameters
struct B{T, X, Y}
    x::X
    y::Y
    B{T}(x::X, y::Y = 2) where {T, X, Y} = new{T, X, Y}(x, y)
end
ConstructionBase.constructorof(::Type{<: B{T}}) where T = B{T}

@testset "type change during @set (custom constructorof)" begin
    obj = B{1}(2,3)
    obj2 = @set obj.y = :three
    @test obj2 === B{1}(2, :three)
end

@testset "text/plain show" begin
    @testset for lens in [
        LensWithTextPlain()
        (@lens _.a) ∘ LensWithTextPlain()
        LensWithTextPlain() ∘ (@lens _.b)
        (@lens _.a) ∘ LensWithTextPlain() ∘ (@lens _.b)
    ]
        @test occursin("I define text/plain.", sprint(show, "text/plain", lens))
    end

    @testset for lens in [
        UserDefinedLens()
        (@lens _.a) ∘ UserDefinedLens()
        UserDefinedLens() ∘ (@lens _.b)
        (@lens _.a) ∘ UserDefinedLens() ∘ (@lens _.b)
    ]
        @test sprint(show, lens) == sprint(show, "text/plain", lens)
    end
end

@testset "Named Tuples" begin
    t = (x=1, y=2)
    @test (@set t.x =2) === (x=2, y=2)
    @test (@set t.x += 2) === (x=3, y=2)
    @test (@set t.x =:hello) === (x=:hello, y=2)
    l = @lens _.x
    @test get(t, l) === 1

    # do we want this to throw an error?
    @test_throws ArgumentError (@set t.z = 3)
end

struct CustomProperties
    _a
    _b
end

function ConstructionBase.setproperties(o::CustomProperties, patch::NamedTuple)
    CustomProperties(get(patch, :a, getfield(o, :_a)),
                     get(patch, :b, getfield(o, :_b)))

end

ConstructionBase.constructorof(::Type{CustomProperties}) = error()

@testset "setproperties overloading" begin
    o = CustomProperties("A", "B")
    o2 = @set o.a = :A
    @test o2 == CustomProperties(:A, "B")
    o3 = @set o.b = :B
    @test o3 == CustomProperties("A", :B)
end

@testset "issue #83" begin
    @test_throws ArgumentError Setfield.lensmacro(identity, :(_.[:a]))
end

@testset "@lens and ∘" begin
    @test @lens(∘()) === @lens(_)
    @test @lens(∘(_.a)) === @lens(_.a)
    @test @lens(∘(_.a, _.b)) === @lens(_.a) ∘ @lens(_.b)
    @test @lens(∘(_.a, _.b, _.c)) === Setfield.compose(@lens(_.a), @lens(_.b), @lens(_.c))

    @test @lens(∘(_[1])) === @lens(_[1])
    @test @lens(∘(_[1], _[2])) === @lens(_[1]) ∘ @lens(_[2])
    @test @lens(∘(_[1], _[2], _[3])) === Setfield.compose(@lens(_[1]), @lens(_[2]), @lens(_[3]))

    @test @lens(_ ∘ (_[1] ∘ _.a) ∘ first(_)) == @lens(_) ∘ (@lens(_[1]) ∘ @lens(_.a)) ∘ @lens(first(_))
end

@testset "@lens ∘ and \$" begin
    lbc = @lens _.b.c
    @test @lens($lbc)== lbc
    @test @lens(_.a ∘ $lbc) == @lens(_.a) ∘ lbc
    @test @lens(_.a ∘ $lbc ∘ _[1] ∘ $lbc) == @lens(_.a) ∘ lbc ∘ @lens(_[1]) ∘ lbc

    # property interpolation
    name = :a
    fancy(name, suffix) = Symbol("fancy_", name, suffix)
    @test @lens(_.$name) == @lens(_.a)
    @test @lens(_.x[1, :].$name) == @lens(_.x[1, :].a)
    @test @lens(_.x[1, :].$(fancy(name, "✨"))) == @lens(_.x[1, :].fancy_a✨)
end

@testset "hasproperty" begin
    obj = (x=1,)

    l1 = @lens _.x
    l2 = @lens _.y

    @test hasproperty(obj, l1)
    @test !hasproperty(obj, l2)
end

end
