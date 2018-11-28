export QuenchLens, StretchLens

function quench0(x)
    if x < 0
        exp(x)
    else
        1 + x
    end
end

function quench_lower(x,lower)
    lower + quench0(x)
end

function quench_upper(x, upper)
    upper - quench0(-x)
end

function quench01(x)
    (atan(x) / pi) + 1//2
end

function quench_lower_upper(x, lower, upper)
    lower + quench01(x) * (upper - lower)
end

function quench(x,lower,upper)
    if isneginf(lower) && isposinf(upper)
        x
    elseif isneginf(lower)
        quench_upper(x,upper)
    elseif isposinf(upper)
        quench_lower(x,lower)
    else
        quench_lower_upper(x,lower,upper)
    end
end

function stretch_lower(y, lower)
    stretch0(y - lower)
end

function stretch_upper(y, upper)
    -stretch0(upper - y)
end

function stretch01(y)
    tan((y - 1//2) * pi)
end

function stretch0(y)
    if y > 1
        y - 1
    else
        log(y)
    end
end

function stretch_lower_upper(y, lower, upper)
    stretch01((y - lower) / (upper - lower))
end

function stretch(y,lower,upper)
    if isneginf(lower) && isposinf(upper)
        y
    elseif isneginf(lower)
        stretch_upper(y,upper)
    elseif isposinf(upper)
        stretch_lower(y,lower)
    else
        stretch_lower_upper(y,lower,upper)
    end
end

function isposinf(x)
    isinf(x) && x > 0
end

function isneginf(x)
    isinf(x) && x < 0
end

struct QuenchLens{T} <: Lens
    lower::T
    upper::T
end

function get(o, l::QuenchLens)
    quench(o, l.lower, l.upper)
end

function set(_, l::QuenchLens, val)
    stretch(val, l.lower, l.upper)
end

struct StretchLens{T} <: Lens
    lower::T
    upper::T
end

Base.inv(l::StretchLens) = QuenchLens(l.lower, l.upper)
Base.inv(l::QuenchLens) = StretchLens(l.lower, l.upper)

function get(o, l::StretchLens)
    stretch(o, l.lower, l.upper)
end

function set(_, l::StretchLens, val)
    quench(val, l.lower, l.upper)
end
