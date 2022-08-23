Base.@propagate_inbounds function setindex(args...)
    Base.setindex(args...)
end

Base.@propagate_inbounds function setindex(xs::AbstractArray, v, I...)
    # we need to distinguish between scalar and sliced assignment
    I_normalized = Base.to_indices(xs, I)
    T = promote_type(eltype(xs), I_normalized isa Tuple{Vararg{Integer}} ? typeof(v) : eltype(v))
    ys = similar(xs, T)
    if eltype(xs) !== Union{}
        copy!(ys, xs)
    end
    ys[I_normalized...] = v
    return ys
end

Base.@propagate_inbounds function setindex(d0::AbstractDict, v, k)
    K = promote_type(keytype(d0), typeof(k))
    V = promote_type(valtype(d0), typeof(v))
    d = empty(d0, K, V)
    copy!(d, d0)
    d[k] = v
    return d
end

setindex(a::StaticArraysCore.StaticArray, args...) =
    Base.setindex(a, args...)
