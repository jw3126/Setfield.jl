# Setfield

[![DocStable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jw3126.github.io/Setfield.jl/stable/intro)
[![DocDev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jw3126.github.io/Setfield.jl/dev/intro)
![CI](https://github.com/jw3126/Setfield.jl/workflows/CI/badge.svg)

Update deeply nested immutable structs.

# Deprecated

`Setfield.jl` is deprecated. Use [Accessors.jl](https://github.com/JuliaObjects/Accessors.jl) instead.
It will not receive further updates and supports Julia versions up to 1.13 only.

# Usage
Updating deeply nested immutable structs was never easier:
```julia
using Setfield
@set obj.a.b.c = d
```
For more information, see [the documentation](https://jw3126.github.io/Setfield.jl/latest/intro/) and/or watch this video:

[![JuliaCon2020 Changing the immutable](https://img.youtube.com/vi/vkAOYeTpLg0/0.jpg)](https://youtu.be/vkAOYeTpLg0 "Changing the immutable")

# Some creative usages of Setfield

* [VegaLite.jl](https://github.com/queryverse/VegaLite.jl) overloads
  `getproperty` and lens API to manipulate JSON-based nested objects.

* [Kaleido.jl](https://github.com/tkf/Kaleido.jl) is a library of
  additional lenses.

* [PhaseSpaceIO.jl](https://github.com/jw3126/PhaseSpaceIO.jl) overloads
  `getproperty` and `setproperties` to get/set values from/in packed bits.
