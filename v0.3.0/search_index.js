var documenterSearchIndex = {"docs": [

{
    "location": "intro.html#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": ""
},

{
    "location": "intro.html#Usage-1",
    "page": "Introduction",
    "title": "Usage",
    "category": "section",
    "text": "Say we have a deeply nested struct:julia> using StaticArrays;\n\njulia> struct Person\n           name::Symbol\n           age::Int\n       end;\n\njulia> struct SpaceShip\n           captain::Person\n           velocity::SVector{3, Float64}\n           position::SVector{3, Float64}\n       end;\n\njulia> s = SpaceShip(Person(:julia, 2009), [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])\nSpaceShip(Person(:julia, 2009), [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])Lets update the captains name:julia> s.captain.name = :JULIA\nERROR: type Person is immutableIt\'s a bit cryptic but what it means that Julia tried very hard to set the field but gave it up since the struct is immutable.  So we have to do:julia> SpaceShip(Person(:JULIA, s.captain.age), s.velocity, s.position)\nSpaceShip(Person(:JULIA, 2009), [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])This is messy and things get worse, if the structs are bigger. Setfields to the rescue!julia> using Setfield\n\njulia> s = @set s.captain.name = :JULIA\nSpaceShip(Person(:JULIA, 2009), [0.0, 0.0, 0.0], [0.0, 0.0, 0.0])\n\njulia> s = @set s.velocity[1] += 999999\nSpaceShip(Person(:JULIA, 2009), [999999.0, 0.0, 0.0], [0.0, 0.0, 0.0])\n\njulia> s = @set s.velocity[1] += 999999\nSpaceShip(Person(:JULIA, 2009), [2.0e6, 0.0, 0.0], [0.0, 0.0, 0.0])\n\njulia> @set s.position[2] = 20\nSpaceShip(Person(:JULIA, 2009), [2.0e6, 0.0, 0.0], [0.0, 20.0, 0.0])"
},

{
    "location": "intro.html#Under-the-hood-1",
    "page": "Introduction",
    "title": "Under the hood",
    "category": "section",
    "text": "Under the hood this package implements a simple lens api. This api may be useful in its own rite and works as follows:julia> using Setfield\n\njulia> l = @lens _.a.b\n(@lens _.a.b)\n\njulia> struct AB;a;b;end\n\njulia> obj = AB(AB(1,2),3)\nAB(AB(1, 2), 3)\n\njulia> set(obj, l, 42)\nAB(AB(1, 42), 3)\n\njulia> obj\nAB(AB(1, 2), 3)\n\njulia> get(obj, l)\n2\n\njulia> modify(x->10x, obj, l)\nAB(AB(1, 20), 3)Now the @set macro simply provides sugar for creating a lens and applying it. For instance@set obj.a.b = 42expands roughly tol = @lens _.a.b\nset(obj, l, 42)"
},

{
    "location": "index.html#",
    "page": "Docstrings",
    "title": "Docstrings",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Setfield.Lens",
    "page": "Docstrings",
    "title": "Setfield.Lens",
    "category": "type",
    "text": "Lens\n\nA Lens allows to access or replace deeply nested parts of complicated objects.\n\nExample\n\njulia> using Setfield\n\njulia> struct T;a;b; end\n\njulia> obj = T(\"AA\", \"BB\")\nT(\"AA\", \"BB\")\n\njulia> lens = @lens _.a\n(@lens _.a)\n\njulia> get(obj, lens)\n\"AA\"\n\njulia> set(obj, lens, 2)\nT(2, \"BB\")\n\njulia> obj\nT(\"AA\", \"BB\")\n\njulia> modify(lowercase, obj, lens)\nT(\"aa\", \"BB\")\n\nInterface\n\nConcrete subtypes of Lens have to implement\n\nset(obj, lens, val)\nget(obj, lens)\n\nThese must be pure functions, that satisfy the three lens laws:\n\n@assert get(set(obj, lens, val), lens) == val\n        # You get what you set.\n@assert set(obj, lens, get(obj, lens)) == obj\n        # Setting what was already there changes nothing.\n@assert set(set(obj, lens, val1), lens, val2) == set(obj, lens, val2)\n        # The last set wins.\n\nSee also @lens, set, get, modify.\n\n\n\n\n\n"
},

{
    "location": "index.html#Base.get",
    "page": "Docstrings",
    "title": "Base.get",
    "category": "function",
    "text": "get(obj, l::Lens)\n\nAccess a deeply nested part of obj. See also Lens.\n\n\n\n\n\n"
},

{
    "location": "index.html#Setfield.modify",
    "page": "Docstrings",
    "title": "Setfield.modify",
    "category": "function",
    "text": "modify(f, obj, l::Lens)\n\nReplace a deeply nested part x of obj by f(x). See also Lens.\n\n\n\n\n\n"
},

{
    "location": "index.html#Setfield.set",
    "page": "Docstrings",
    "title": "Setfield.set",
    "category": "function",
    "text": "set(obj, l::Lens, val)\n\nReplace a deeply nested part of obj by val. See also Lens.\n\n\n\n\n\n"
},

{
    "location": "index.html#Setfield.@lens-Tuple{Any}",
    "page": "Docstrings",
    "title": "Setfield.@lens",
    "category": "macro",
    "text": "@lens\n\nConstruct a lens from a field access.\n\nExample\n\njulia> using Setfield\n\njulia> struct T;a;b;end\n\njulia> t = T(\"A1\", T(T(\"A3\", \"B3\"), \"B2\"))\nT(\"A1\", T(T(\"A3\", \"B3\"), \"B2\"))\n\njulia> l = @lens _.b.a.b\n(@lens _.b.a.b)\n\njulia> get(t, l)\n\"B3\"\n\njulia> set(t, l, 100)\nT(\"A1\", T(T(\"A3\", 100), \"B2\"))\n\njulia> t = (\"one\", \"two\")\n(\"one\", \"two\")\n\njulia> set(t, (@lens _[1]), \"1\")\n(\"1\", \"two\")\n\n\n\n\n\n"
},

{
    "location": "index.html#Setfield.@set-Tuple{Any}",
    "page": "Docstrings",
    "title": "Setfield.@set",
    "category": "macro",
    "text": "@set assignment\n\nReturn a modified copy of deeply nested objects.\n\nExample\n\njulia> using Setfield\n\njulia> struct T;a;b end\n\njulia> t = T(1,2)\nT(1, 2)\n\njulia> @set t.a = 5\nT(5, 2)\n\njulia> t\nT(1, 2)\n\njulia> t = @set t.a = T(2,2)\nT(T(2, 2), 2)\n\njulia> @set t.a.b = 3\nT(T(2, 3), 2)\n\n\n\n\n\n"
},

{
    "location": "index.html#Base.:∘-Tuple{Lens,Lens}",
    "page": "Docstrings",
    "title": "Base.:∘",
    "category": "method",
    "text": "lens₁ ∘ lens₂\ncompose([lens₁, [lens₂, [lens₃, ...]]])\n\nCompose lenses lens₁, lens₂, ..., lensₙ to access nested objects.\n\nExample\n\njulia> using Setfield\n\njulia> obj = (a = (b = (c = 1,),),);\n\njulia> la = @lens _.a\n       lb = @lens _.b\n       lc = @lens _.c\n       lens = la ∘ lb ∘ lc\n(@lens _.a.b.c)\n\njulia> get(obj, lens)\n1\n\n\n\n\n\n"
},

{
    "location": "index.html#Docstrings-1",
    "page": "Docstrings",
    "title": "Docstrings",
    "category": "section",
    "text": "Modules = [Setfield]"
},

]}
