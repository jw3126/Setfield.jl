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
    # GroundEffects handles dot calls here but we don't need to do
    # this because `setindex(::Tuple, ::Tuple, ::Tuple)` is not
    # supported.
    if isexpr(index, :call)
        return Expr(:call, lower_indices(lower, collection, index.args)...)
    elseif index === :end
        return :($(Base.lastindex)($collection))
    end
    return lower(index)
end

end  # module
