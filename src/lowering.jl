module Lowering

using Base.Meta: isexpr

"""
    lower(ex)

A modified version of `GroundEffects.lower` that only handles indexing.
"""
lower(ex) = something(handle_ref(lower, ex), ex)

function handle_ref(lower, ex)
    isexpr(ex, :ref) || return nothing
    statements, collection, indices = _handle_ref(lower, ex)
    push!(statements, Expr(:call, Base.getindex, collection, indices...))
    if length(statements) == 1
        return statements[1]
    else
        return Expr(:block, statements...)
    end
end

function _handle_ref(lower, ex)
    statements = []
    if length(ex.args) == 1
        collection = ex.args[1]
        indices = []
    else
        if ex.args[1] isa Symbol
            collection = ex.args[1]
        else
            @gensym collection
            push!(statements, :($collection = $(ex.args[1])))
        end
        indices = lower_indices(lower, collection, ex.args[2:end])
    end
    return statements, collection, indices
end

lower_indices(lower, collection, indices) =
    map(index -> lower_index(lower, collection, index), indices)

function lower_index(lower, collection, index)
    ex = handle_dotcall(index) do ex
        lower_index(lower, collection, ex)
    end
    ex === nothing || return something(ex)

    if isexpr(index, :call)
        return Expr(:call, lower_indices(lower, collection, index.args)...)
    elseif index === :end
        return :($(Base.lastindex)($collection))
    end
    return lower(index)
end

function isdotopcall(ex)
    ex isa Expr && !isempty(ex.args) || return false
    op = ex.args[1]
    return op isa Symbol && Base.isoperator(op) && startswith(string(op), ".")
end

isdotcall(ex) =
    isexpr(ex, :.) && length(ex.args) == 2 && isexpr(ex.args[2], :tuple)

function handle_dotcall(lower, ex)
    isdotcall(ex) || isdotopcall(ex) || return nothing
    return Expr(:call, Base.materialize, handle_lazy_dotcall(lower, ex))
end

function handle_lazy_dotcall(lower, ex)
    if isdotcall(ex)
        args = [
            lower(ex.args[1])
            map(x -> handle_lazy_dotcall(lower, x), ex.args[2].args)
        ]
    elseif isdotopcall(ex)
        args = [
            Symbol(String(ex.args[1])[2:end])
            map(x -> handle_lazy_dotcall(lower, x), ex.args[2:end])
        ]
    else
        return lower(ex)
    end
    return Expr(:call, Base.broadcasted, args...)
end

end  # module
