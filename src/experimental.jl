"""
    Experimental

This module contains experimental features. These features may be changed or removed anytime, without warning.
"""
module Experimental
using Setfield
using Setfield: constructor_of, Lens, ComposedLens
import Setfield: get, set
export SingletonLens
export VCatLens
export MultiPropertyLens

const NNamedTupleLens{N,s} = NamedTuple{s, T} where {T <: NTuple{N, Lens}}
struct MultiPropertyLens{L <: NNamedTupleLens} <: Lens
    lenses::L
end

_keys(::Type{MultiPropertyLens{NamedTuple{s,T}}}) where {s,T} = s
@generated function get(obj, l::MultiPropertyLens)
    get_arg(fieldname) = :($fieldname = get(obj.$fieldname, l.lenses.$fieldname))
    args = map(get_arg, _keys(l))
    Expr(:tuple, args...)
end

@generated function set(obj, l::MultiPropertyLens, val)
    T = obj
    args = map(fieldnames(T)) do fn
        if fn in _keys(l)
            quote
                obj_inner = obj.$fn
                lens_inner = l.lenses.$fn
                val_inner = val.$fn
                set(obj_inner, lens_inner, val_inner)
            end
        else
            :(obj.$fn)
        end
    end
    Expr(:block,
        Expr(:meta, :inline),
        Expr(:call, :(constructor_of($T)), args...)
    )
end

function Base.show(io::IO, l::MultiPropertyLens)
    print(io, "MultiPropertyLens(")
    print(io, l.lenses)
    print(io, ')')
end

struct SingletonLens <: Lens
end

function get(o, l::SingletonLens)
    [o]
end
function set(o, l::SingletonLens, arr)
    first(arr)
end

const Lenses{N} = NTuple{N,Lens}
struct VCatLens{Ls <: Lenses} <: Lens
    lenses::Ls
end

function VCatLens(lenses...)
    VCatLens(lenses)
end
function VCatLens(lenses::L) where {L <: Tuple}
    VCatLens{L}(lenses)
end

function length_get(o,l::SingletonLens)
    1
end

function length_get(o,l)
    length(get(o,l))
end

function length_get(o, l::ComposedLens{L,SingletonLens}) where {L}
    1
end

function length_get(o,l::VCatLens)
    sum(l.lenses) do li
        length_get(o,li)
    end
end

function get(o,l::VCatLens)
    pieces = map(l.lenses) do li
        get(o, li)
    end
    vcat(pieces...)
end

function set(o, l::VCatLens, arr)
    lengths = map(l.lenses) do li
        length_get(o, li)
    end
    pieces = partition(arr, lengths)
    setall(o, l.lenses, pieces)
end
function _ranges(offset,l)
    ((offset+1):(offset+l),)
end
function _ranges(offset,l,ls...)
    r1 = (offset+1):(offset+l)
    rs = _ranges(offset+l, ls...)
    tuple(r1, rs...)
end
    
function partition(arr, lengths)
    indexes = _ranges(0, lengths...)
    map(indexes) do index
        view(arr, index)
    end
end

function setall(o, lenses::Tuple{}, vals::Tuple{})
    o
end
function setall(o, lenses::Lenses{N}, vals::NTuple{N, Any}) where {N}
    o2 = set(o, first(lenses), first(vals))
    setall(o2, Base.tail(lenses), Base.tail(vals))
end
end
