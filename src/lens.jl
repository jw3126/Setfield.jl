export Lens, set, get, modify
export @lens
export set, get, modify
using ConstructionBase
export setproperties
export constructorof


import Base: get
using Base: setindex, getproperty

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

```jldoctest; output = false, setup = :(using Setfield; obj = (a="A", b="B"); lens = @lens _.a; val = 2; val1 = 10; val2 = 20)
@assert get(set(obj, lens, val), lens) == val
		# You get what you set.
@assert set(obj, lens, get(obj, lens)) == obj
		# Setting what was already there changes nothing.
@assert set(set(obj, lens, val1), lens, val2) == set(obj, lens, val2)
		# The last set wins.

# output

```

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


"""
	MutationPolicy(lens::Lens)
	MutationPolicy(::Type{<:Lens})

	MutationPolicy specifies if and how a `Lens` should mutate
	an object in a call to [`set`](@ref). When you define a new Lens
	type, you can set this trait using the following options:
		- `NeverMutate()`: always create a new, modified copy.
		- `AlwaysMutate()`: modify the object in-place
		- `MaybeMutate()`: modify the object if it is mutable, otherwise create a new, modified copy.
	where:
		`Setfield.MutationPolicy(::Type{<:Lens}) = NeverMutate()`
    is the default.
"""
abstract type MutationPolicy end
struct NeverMutate <: MutationPolicy end
struct AlwaysMutate <: MutationPolicy end
struct MaybeMutate <: MutationPolicy end

MutationPolicy(l::Lens) = MutationPolicy(typeof(l))
MutationPolicy(::Type{<:Lens}) = NeverMutate()

mutation_policies(l::Lens) = (MutationPolicy(l),)
mutation_policies(l::Lens, ls::Lens...) = (MutationPolicy(l), mutation_policies(ls...)...)


@inline function modify(f, obj, l::Lens)
	old_val = get(obj, l)
	new_val = f(old_val)
	set(obj, l, new_val)
end

struct IdentityLens <: Lens end
get(obj, ::IdentityLens) = obj
set(obj, ::IdentityLens, val) = val
MutationPolicy(::Type{IdentityLens}) = NeverMutate()


struct PropertyLens{name, Policy} <: Lens
	PropertyLens{name, Policy}() where {name, Policy} = new{name::Symbol, Policy::MutationPolicy}()
end

MutationPolicy(::Type{<:PropertyLens{name, Policy}}) where {name, Policy} = Policy

function get(obj, l::PropertyLens{name}) where {name}
	getproperty(obj, name)
end

@generated function set(obj, l::PropertyLens{name, NeverMutate()}, val) where {name}
	Expr(:block,
		 Expr(:meta, :inline),
		:(setproperties(obj, ($name=val,)))
	   )
end
@inline set(obj, l::PropertyLens{name, AlwaysMutate()}, val) where {name} =
	setproperty!(obj, name, val)
@inline set(obj, l::PropertyLens{name, MaybeMutate()}, val) where {name} =
	setproperty!!(obj, name, val)


struct ComposedLens{LO, LI} <: Lens
	outer::LO
	inner::LI
end

compose() = IdentityLens()
compose(l::Lens) = l
compose(::IdentityLens, ::IdentityLens) = IdentityLens()
compose(::IdentityLens, l::Lens) = l
compose(l::Lens, ::IdentityLens) = l
compose(outer::Lens, inner::Lens) = ComposedLens(outer, inner)
function compose(l1::Lens, ls::Lens...)
	# We can build _.a.b.c as (_.a.b).c or _.a.(b.c)
	# The compiler prefers (_.a.b).c
	compose(l1, compose(ls...))
end

"""
	lens₁ ∘ lens₂
	compose([lens₁, [lens₂, [lens₃, ...]]])

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

struct IndexLens{I <: Tuple, Policy} <: Lens
	indices::I
	IndexLens{I, Policy}(indices::I) where {I, Policy} = new{I, Policy::MutationPolicy}(indices)
end

MutationPolicy(::Type{<:IndexLens{<:Tuple, Policy}}) where {Policy} = Policy

Base.@propagate_inbounds get(obj, l::IndexLens) =
	getindex(obj, l.indices...)

Base.@propagate_inbounds set(obj, l::IndexLens{<:Tuple, NeverMutate()}, val) =
	setindex(obj, val, l.indices...)
Base.@propagate_inbounds set(obj, l::IndexLens{<:Tuple, AlwaysMutate()}, val) =
	setindex!(obj, val, l.indices...)
Base.@propagate_inbounds set(obj, l::IndexLens{<:Tuple, MaybeMutate()}, val) =
	setindex!!(obj, val, l.indices...)

"""
	ConstIndexLens{I}

Lens with index stored in type parameter.  This is useful for type-stable
[`get`](@ref) and [`set`](@ref) operations on tuples and named tuples.

This lens can be constructed by, e.g., `@lens _[\$1]`.  Complex expression
must be wrapped with `\$(...)` like `@lens _[\$(length(xs))]`.

# Examples
```jldoctest
julia> using Setfield

julia> get((1, 2.0), @lens _[\$1])
1

julia> Base.promote_op(get, typeof.(((1, 2.0), @lens _[\$1]))...)
Int64

julia> Base.promote_op(get, typeof.(((1, 2.0), @lens _[1]))...) !== Int
true
```
"""
struct ConstIndexLens{I, Policy} <: Lens
	ConstIndexLens{I, Policy}() where {I, Policy} = new{I, Policy::MutationPolicy}()
end

Base.@propagate_inbounds get(obj, ::ConstIndexLens{I}) where I = obj[I...]

Base.@propagate_inbounds set(obj, ::ConstIndexLens{I, NeverMutate()}, val) where I =
	setindex(obj, val, I...)
Base.@propagate_inbounds set(obj, ::ConstIndexLens{I, AlwaysMutate()}, val) where I =
	setindex!(obj, val, I...)
Base.@propagate_inbounds set(obj, ::ConstIndexLens{I, MaybeMutate()}, val) where I =
	setindex!!(obj, val, I...)


@inline set(obj::Union{Tuple, NamedTuple}, l::ConstIndexLens{I, MaybeMutate()}, val) where I = _settuple(obj, l, val)
@inline set(obj::Union{Tuple, NamedTuple}, l::ConstIndexLens{I, NeverMutate()}, val) where I = _settuple(obj, l, val)
@generated function _settuple(obj, ::ConstIndexLens{I}, val) where {I}
	if length(I) == 1
		n, = I
		args = map(1:length(obj.types)) do i
			i == n ? :val : :(obj[$i])
		end
		quote
			$(Expr(:meta, :inline))
			($(args...),)
		end
	else
		quote
			throw(ArgumentError($(string(
				"A `Tuple` and `NamedTuple` can only be indexed with one ",
				"integer.  Given: $I"))))
		end
	end
end

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

Base.@deprecate constructor_of(T) constructorof(T)
Base.@deprecate get(lens::Lens, obj)       get(obj, lens)
Base.@deprecate set(lens::Lens, obj, val)  set(obj, lens, val)
Base.@deprecate modify(f, lens::Lens, obj) modify(f, obj, lens)
