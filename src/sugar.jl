export @set, @lens
using MacroTools

"""
    @set assignment

Return a modified copy of deeply nested objects.

# Example
```jldoctest
julia> using Setfield

julia> struct T;a;b end

julia> t = T(1,2)
T(1, 2)

julia> @set t.a = 5
T(5, 2)

julia> t
T(1, 2)

julia> t = @set t.a = T(2,2)
T(T(2, 2), 2)

julia> @set t.a.b = 3
T(T(2, 3), 2)
```
"""
macro set(ex)
    atset_impl(ex)
end

function parse_obj_lenses(ex)
    if @capture(ex, front_[indices__])
        obj, frontlens = parse_obj_lenses(front)
        index = esc(Expr(:tuple, indices...))
        lens = :(IndexLens($index))
    elseif @capture(ex, front_.property_)
        obj, frontlens = parse_obj_lenses(front)
        lens = :(PropertyLens{$(QuoteNode(property))}())
    else
        obj = esc(ex)
        return obj, ()
    end
    obj, tuple(frontlens..., lens)
end

function parse_obj_lens(ex)
    obj, lenses = parse_obj_lenses(ex)
    lens = Expr(:call, :compose, lenses...)
    obj, lens
end

function get_update_op(sym::Symbol)
    s = String(sym)
    if !endswith(s, '=') || isdefined(Base, sym)
        # 'x +=' etc. is actually 'x = x +', and so '+=' isn't defined in Base.
        # '>=' however is a function, and not an assignment operator.
        msg = "Operation $sym doesn't look like an assignment"
        throw(ArgumentError(msg))
    end
    Symbol(s[1:end-1])
end

struct _UpdateOp{OP,V}
    op::OP
    val::V
end
(u::_UpdateOp)(x) = u.op(x, u.val)

function atset_impl(ex::Expr)
    @assert ex.head isa Symbol
    @assert length(ex.args) == 2
    ref, val = ex.args
    obj, lens = parse_obj_lens(ref)
    val = esc(val)
    ret = if ex.head == :(=)
        quote
            lens = $lens
            set($obj, lens, $val)
        end
    else
        op = get_update_op(ex.head)
        f = :(_UpdateOp($op,$val))
        quote
            modify($f, $obj, $lens)
        end
    end
    ret
end

"""
    @lens

Construct a lens from a field access.

# Example

```jldoctest
julia> using Setfield

julia> struct T;a;b;end

julia> t = T("A1", T(T("A3", "B3"), "B2"))
T("A1", T(T("A3", "B3"), "B2"))

julia> l = @lens _.b.a.b
(@lens _.b.a.b)

julia> get(t, l)
"B3"

julia> set(t, l, 100)
T("A1", T(T("A3", 100), "B2"))

julia> t = ("one", "two")
("one", "two")

julia> set(t, (@lens _[1]), "1")
("1", "two")
```

"""
macro lens(ex)
    obj, lens = parse_obj_lens(ex)
    if obj != esc(:_)
        msg = """Cannot parse lens $ex. Lens expressions must start with @lens _"""
        throw(ArgumentError(msg))
    end
    lens
end

has_atlens_support(::Any) = false
has_atlens_support(::Union{PropertyLens, IndexLens, IdentityLens}) = true
has_atlens_support(l::ComposedLens) =
    has_atlens_support(l.outer) && has_atlens_support(l.inner)

print_application(io::IO, l::PropertyLens{field}) where {field} = print(io, ".", field)
print_application(io::IO, l::IndexLens) = print(io, "[", join(l.indices, ", "), "]")
print_application(io::IO, l::IdentityLens) = print(io, "")

function print_application(io::IO, l::ComposedLens)
    print_application(io, l.outer)
    print_application(io, l.inner)
end

function Base.show(io::IO, l::Lens)
    if has_atlens_support(l)
        print_in_atlens(io, l)
    else
        show_generic(io, l)
    end
end

function Base.show(io::IO, l::ComposedLens)
    if has_atlens_support(l)
        print_in_atlens(io, l)
    else
        show(io, l.outer)
        print(io, " ∘ ")
        show(io, l.inner)
    end
end

function print_in_atlens(io, l)
    print(io, "(@lens _")
    print_application(io, l)
    print(io, ')')
end

function show_generic(io::IO, args...)
    types = tuple(typeof(io), Base.Iterators.repeated(Any, length(args))...)
    Types = Tuple{types...}
    invoke(show, Types, io, args...)
end
show_generic(args...) = show_generic(stdout, args...)
