export @set, @set!, @set!!, @lens, @lens!, @lens!!
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
    atset_impl(ex, NeverMutate())
end

"""
    @set! assignment

Shortcut for `obj = @set obj...`.

julia> t = (a=1,)
(a = 1,)

julia> @set! t.a=2
(a = 2,)

julia> t
(a = 2,)
"""
macro set!(ex)
    atset_impl(ex, AlwaysMutate())
end

macro set!!(ex)
    atset_impl(ex, MaybeMutate())
end

is_interpolation(x) = x isa Expr && x.head == :$

function parse_obj_lenses(ex, policy::MutationPolicy)
    if @capture(ex, front_[indices__])
        obj, frontlens = parse_obj_lenses(front, policy)
        if any(is_interpolation, indices)
            if !all(is_interpolation, indices)
                throw(ArgumentError(string(
                    "Constant and non-constant indexing (i.e., indices",
                    " with and without \$) cannot be mixed.")))
            end
            index = esc(Expr(:tuple, [x.args[1] for x in indices]...))
            lens = :(ConstIndexLens{$index, $policy}())
        else
            index = esc(Expr(:tuple, indices...))
            lens = :(IndexLens{typeof($index), $policy}($index))
        end
    elseif @capture(ex, front_.property_)
        obj, frontlens = parse_obj_lenses(front, policy)
        lens = :(PropertyLens{$(QuoteNode(property)), $policy}())
    elseif @capture(ex, f_(front_))
        obj, frontlens = parse_obj_lenses(front, policy)
        lens = :(FunctionLens($(esc(f))))
    else
        obj = esc(ex)
        return obj, ()
    end
    obj, tuple(frontlens..., lens)
end

function parse_obj_lens(ex, policy::MutationPolicy)
    obj, lenses = parse_obj_lenses(ex, policy)
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

function atset_impl(ex::Expr, policy::MutationPolicy)
    @assert ex.head isa Symbol
    @assert length(ex.args) == 2
    ref, val = ex.args
    obj, lens = parse_obj_lens(ref, policy)
    dst = gensym("_")
    val = esc(val)
    ret = if ex.head == :(=)
        quote
            lens = $lens
            $dst = set($obj, lens, $val)
        end
    else
        op = get_update_op(ex.head)
        f = :(_UpdateOp($op,$val))
        quote
            $dst = modify($f, $obj, $lens)
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
    obj, lens = parse_obj_lens(ex, NeverMutate())
    if obj != esc(:_)
        msg = """Cannot parse lens $ex. Lens expressions must start with @lens _"""
        throw(ArgumentError(msg))
    end
    lens
end

macro lens!(ex)
    obj, lens = parse_obj_lens(ex, AlwaysMutate())
    if obj != esc(:_)
        msg = """Cannot parse lens $ex. Lens expressions must start with @lens _"""
        throw(ArgumentError(msg))
    end
    lens
end

macro lens!!(ex)
    obj, lens = parse_obj_lens(ex, MaybeMutate())
    if obj != esc(:_)
        msg = """Cannot parse lens $ex. Lens expressions must start with @lens _"""
        throw(ArgumentError(msg))
    end
    lens
end

has_atlens_support(l::Lens) = has_atlens_support(typeof(l))
has_atlens_support(::Type{<:Lens}) = false
has_atlens_support(::Type{<:Union{PropertyLens, IndexLens, ConstIndexLens, FunctionLens, IdentityLens}}) =
    true
has_atlens_support(::Type{ComposedLens{LO, LI}}) where {LO, LI} =
    has_atlens_support(LO) && has_atlens_support(LI)

print_application(io::IO, l::PropertyLens{field}) where {field} = print(io, ".", field)
print_application(io::IO, l::IndexLens) = print(io, "[", join(repr.(l.indices), ", "), "]")
print_application(io::IO, ::ConstIndexLens{I}) where I =
    print(io, "[", join(string.("\$", I), ", "), "]")
print_application(io::IO, l::IdentityLens) = print(io, "")

function print_application(io::IO, l::ComposedLens)
    print_application(io, l.outer)
    print_application(io, l.inner)
end

function print_application(printer, io, ::FunctionLens{f}) where f
    print(io, f, '(')
    printer(io)
    print(io, ')')
end

function print_application(printer, io, l)
    @assert has_atlens_support(l)
    printer(io)
    print_application(io, l)
end

function print_application(printer, io, l::ComposedLens)
    print_application(io, l.inner) do io
        print_application(printer, io, l.outer)
    end
end

# Since `show` of `ComposedLens` needs to call `show` of other lenses,
# we explicitly define text/plain `show` for `ComposedLens` to propagate
# the "context" (2-arg or 3-arg `show`) with which `show` has to be called.
# See: https://github.com/jw3126/Setfield.jl/pull/86
Base.show(io::IO, ::MIME"text/plain", l::ComposedLens) =
    _show(io, MIME("text/plain"), l)

function _show(io::IO, mime, l::Lens)
    if has_atlens_support(l)
        print_in_atlens(io, l)
    elseif mime === nothing
        show(io, l)
    else
        show(io, mime, l)
    end
end

function _show(io::IO, mime, l::ComposedLens)
    if has_atlens_support(l)
        print_in_atlens(io, l)
    else
        _show(io, mime, l.outer)
        print(io, " ∘ ")
        _show(io, mime, l.inner)
    end
end

function print_in_atlens(io, l)
    print(io, "(@lens ")
    print_application(io, l) do io
        print(io, '_')
    end
    print(io, ')')
end
