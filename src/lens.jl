export Lens, set, get, modify
export @lens
export set, get, modify
using ConstructionBase
export setproperties
export constructorof


import Base: get, hash, ==
using Base: getproperty


# used for hashing
function make_salt(s64::UInt64)::UInt
    if UInt === UInt64
        return s64
    else
        return UInt32(s64 >> 32) ^ UInt32(s64 & 0x00000000ffffffff)
    end
end


"""
    Lens

A `Lens` allows to access or replace deeply nested parts of complicated objects.

# Example
```jldoctest
julia> using Setfield

julia> struct T;a;b; end

julia> obj = T("AA", "BB")
T("AA", "BB")

julia> lens = @lens _.a
(@lens _.a)

julia> get(obj, lens)
"AA"

julia> set(obj, lens, 2)
T(2, "BB")

julia> obj
T("AA", "BB")

julia> modify(lowercase, obj, lens)
T("aa", "BB")
```

# Interface
Concrete subtypes of `Lens` have to implement
* `set(obj, lens, val)`
* `get(obj, lens)`

These must be pure functions, that satisfy the three lens laws:

```jldoctest; output = false, setup = :(using Setfield; (≅ = (==)); obj = (a="A", b="B"); lens = @lens _.a; val = 2; val1 = 10; val2 = 20)
@assert get(set(obj, lens, val), lens) ≅ val
        # You get what you set.
@assert set(obj, lens, get(obj, lens)) ≅ obj
        # Setting what was already there changes nothing.
@assert set(set(obj, lens, val1), lens, val2) ≅ set(obj, lens, val2)
        # The last set wins.

# output

```
Here `≅` is an appropriate notion of equality or an approximation of it. In most contexts
this is simply `==`. But in some contexts it might be `===`, `≈`, `isequal` or something
else instead. For instance `==` does not work in `Float64` context, because
`get(set(obj, lens, NaN), lens) == NaN` can never hold. Instead `isequal` or
`≅(x::Float64, y::Float64) = isequal(x,y) | x ≈ y` are possible alternatives.

See also [`@lens`](@ref), [`set`](@ref), [`get`](@ref), [`modify`](@ref).
"""
abstract type Lens end

"""
    modify(f, obj, l::Lens)

Replace a deeply nested part `x` of `obj` by `f(x)`. See also [`Lens`](@ref).
"""
function modify end


"""
    get(obj, l::Lens)

Access a deeply nested part of `obj`. See also [`Lens`](@ref).
"""
function get end

"""
    set(obj, l::Lens, val)

Replace a deeply nested part of `obj` by `val`. See also [`Lens`](@ref).
"""
function set end

@inline function modify(f, obj, l::Lens)
    old_val = get(obj, l)
    new_val = f(old_val)
    set(obj, l, new_val)
end

struct IdentityLens <: Lens end
get(obj, ::IdentityLens) = obj
set(obj, ::IdentityLens, val) = val


struct PropertyLens{fieldname} <: Lens end

function get(obj, l::PropertyLens{field}) where {field}
    getproperty(obj, field)
end

@inline function set(obj, l::PropertyLens{field}, val) where {field}
    patch = (;field => val)
    setproperties(obj, patch)
end

struct ComposedLens{LO, LI} <: Lens
    outer::LO
    inner::LI
end

function ==(l1::ComposedLens, l2::ComposedLens)
    return l1.outer == l2.outer && l1.inner == l2.inner
end

const SALT_COMPOSEDLENS = make_salt(0xcf7322dcc2129a31)
hash(l::ComposedLens, h::UInt) = hash(l.outer, hash(l.inner, SALT_INDEXLENS + h))

"""
    compose([lens₁, [lens₂, [lens₃, ...]]])

Compose `lens₁`, `lens₂` etc. There is one subtle point here:
While the two composition orders `(lens₁ ∘ lens₂) ∘ lens₃` and `lens₁ ∘ (lens₂ ∘ lens₃)` have equivalent semantics,
their performance may not be the same. The compiler tends to optimize right associative composition
(second case) better then left associative composition.

The compose function tries to use a composition order, that the compiler likes. The composition order is therefore not part of the stable API.
"""
function compose end
compose() = IdentityLens()
compose(l::Lens) = l
compose(::IdentityLens, ::IdentityLens) = IdentityLens()
compose(::IdentityLens, l::Lens) = l
compose(l::Lens, ::IdentityLens) = l
compose(outer::Lens, inner::Lens) = ComposedLens(outer, inner)
function compose(l1::Lens, ls::Lens...)
    compose(l1, compose(ls...))
end

"""
    lens₁ ∘ lens₂

Compose lenses `lens₁`, `lens₂`, ..., `lensₙ` to access nested objects.

# Example
```jldoctest
julia> using Setfield

julia> obj = (a = (b = (c = 1,),),);

julia> la = @lens _.a
       lb = @lens _.b
       lc = @lens _.c
       lens = la ∘ lb ∘ lc
(@lens _.a.b.c)

julia> get(obj, lens)
1
```
"""
Base.:∘(l1::Lens, l2::Lens) = compose(l1, l2)

function get(obj, l::ComposedLens)
    inner_obj = get(obj, l.outer)
    get(inner_obj, l.inner)
end

function set(obj,l::ComposedLens, val)
    inner_obj = get(obj, l.outer)
    inner_val = set(inner_obj, l.inner, val)
    set(obj, l.outer, inner_val)
end

struct IndexLens{I <: Tuple} <: Lens
    indices::I
end

==(l1::IndexLens, l2::IndexLens) = l1.indices == l2.indices

const SALT_INDEXLENS = make_salt(0x8b4fd6f97c6aeed6)
hash(l::IndexLens, h::UInt) = hash(l.indices, SALT_INDEXLENS + h)

Base.@propagate_inbounds function get(obj, l::IndexLens)
    getindex(obj, l.indices...)
end
Base.@propagate_inbounds function set(obj, l::IndexLens, val)
    setindex(obj, val, l.indices...)
end

struct DynamicIndexLens{F} <: Lens
    f::F
end

Base.@propagate_inbounds get(obj, I::DynamicIndexLens) = obj[I.f(obj)...]

Base.@propagate_inbounds set(obj, I::DynamicIndexLens, val) =
    setindex(obj, val, I.f(obj)...)

"""
    FunctionLens(f)
    @lens f(_)

Lens with [`get`](@ref) method definition that simply calls `f`.
[`set`](@ref) method for each function `f` must be implemented manually.
Use `methods(set, (Any, Setfield.FunctionLens, Any))` to get a list of
supported functions.

Note that `FunctionLens` flips the order of composition; i.e.,
`(@lens f(_)) ∘ (@lens g(_)) == @lens g(f(_))`.

# Example
```jldoctest
julia> using Setfield

julia> obj = ((1, 2), (3, 4));

julia> lens = (@lens first(_)) ∘ (@lens last(_))
(@lens last(first(_)))

julia> get(obj, lens)
2

julia> set(obj, lens, '2')
((1, '2'), (3, 4))
```

# Implementation

To use `myfunction` as a lens, define a `set` method with the following
signature:

```julia
Setfield.set(obj, ::typeof(@lens myfunction(_)), val) = ...
```

`typeof` is used above instead of `FunctionLens` because how actual
type of `@lens myfunction(_)` is implemented is not the part of stable
API.
"""
struct FunctionLens{f} <: Lens end
FunctionLens(f) = FunctionLens{f}()

get(obj, ::FunctionLens{f}) where f = f(obj)


Base.hasproperty(obj, l::Setfield.ComposedLens) = hasproperty(obj, l.outer)
Base.hasproperty(obj, l::PropertyLens{f}) where f = hasproperty(obj, f)