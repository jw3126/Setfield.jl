__precompile__(true)
module Setfield

export @set

function check_field_exists(T::Type, field::Symbol)
    if !(field ∈ fieldnames(T))
        msg = "$T has no field $field"
        throw(ArgumentError(msg))
    end
end

function setfield_impl(obj, field::Symbol, val)
    T = obj
    check_field_exists(T, field)
    fieldvals = map(fieldnames(T)) do fn
        fn == field ? :(val) : :(obj.$fn)
    end
    Expr(:block,
        Expr(:meta, :inline),
        Expr(:call, T, fieldvals...)
    )
end

@generated function setfield(obj, ::Val{field}, val) where {field}
    @assert field isa Symbol
    setfield_impl(obj ,field, val)
end

function setdeepfield_impl(obj, path::NTuple{N,Symbol}, val) where {N}
    @assert N > 0
    @assert length(path) > 0
    head = first(path)
    check_field_exists(obj, head)
    vhead = QuoteNode(Val{first(path)}())
    vtail = QuoteNode(Val{Base.tail(path)}())
    ex = if N == 1
        quote
            setfield(obj, $vhead, val)
        end
    else
        quote
            inner_object = obj.$(head)
            inner = setdeepfield(inner_object, $vtail, val)
            setfield(obj, $vhead, inner)
        end
    end
    unshift!(ex.args, Expr(:meta, :inline))
    ex
end

@generated function setdeepfield(obj, ::Val{path}, val) where {path}
    @assert path isa Tuple
    setdeepfield_impl(obj, path, val)
end

function unquote(ex::QuoteNode)
    ex.value
end
function unquote(ex::Expr)
    @assert Meta.isexpr(ex, :quote)
    @assert length(ex.args) == 1
    first(ex.args)
end

function destruct_assignment(ex)
    @assert Meta.isexpr(ex, Symbol("="))
    @assert length(ex.args) == 2
    tuple(ex.args...)
end

function destruct_fieldref(ex)
    @assert Meta.isexpr(ex, Symbol("."))
    @assert length(ex.args) == 2
    a, qb = ex.args
    a, unquote(qb)
end

function destruct_deepfieldref(s::Symbol)
    s, ()
end
    
function destruct_deepfieldref(ex)
    front, last = destruct_fieldref(ex)
    a, middle = destruct_deepfieldref(front)
    a, tuple(middle..., last)
end

function destruct_deepassignment(ex)
    ref, val = destruct_assignment(ex)
    obj, path = destruct_deepfieldref(ref)
    obj, path, val
end

"""
    @set assignment

Update deeply nested fields of an immutable object.
```jldoctest
julia> struct T; a; b end

julia> t = T(1,T(2,2))
T(1, T(2, 2))

julia> @set t.a=5
T(5, T(2, 2))

julia> @set t.b.a = 5
T(1, T(5, 2))
```
"""
macro set(ex)
    obj, path, val = destruct_deepassignment(ex)
    vpath = QuoteNode(Val{path}())
    quote
        $(esc(obj)) = Setfield.setdeepfield(
                                            $(esc(obj)), 
                                            $vpath, 
                                            $(esc(val)))
    end
end

end
