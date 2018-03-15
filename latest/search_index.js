var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Setfield.Lens",
    "page": "Home",
    "title": "Setfield.Lens",
    "category": "type",
    "text": "Lens\n\nA Lens allows to access or replace deeply nested parts of complicated objects.\n\nExample\n\njulia> using Setfield\n\njulia> struct T;a;b; end\n\njulia> t = T(\"AA\", \"BB\")\nT(\"AA\", \"BB\")\n\njulia> l = @lens _.a\n(@lens _.a)\n\njulia> get(l, t)\n\"AA\"\n\njulia> set(l, t, 2)\nT(2, \"BB\")\n\njulia> t\nT(\"AA\", \"BB\")\n\njulia> modify(lowercase, l, t)\nT(\"aa\", \"BB\")\n\nInterface\n\nConcrete subtypes of Lens have to implement\n\nset(lens, obj, val)\nget(lens, obj)\n\nThese must be pure functions, that satisfy the three lens laws:\n\nget(lens, set(lens, obj, val)) == val (You get what you set.)\nset(lens, obj, get(lens, obj)) == obj (Setting what was already there changes nothing.)\nset(lens, set(lens, obj, val1), val2) == set(lens, obj, val2) (The last set wins.)\n\nSee also @lens, set, get, modify.\n\n\n\n"
},

{
    "location": "index.html#Base.get",
    "page": "Home",
    "title": "Base.get",
    "category": "function",
    "text": "get(l::Lens, obj)\n\nAccess a deeply nested part of obj. See also Lens.\n\n\n\n"
},

{
    "location": "index.html#Setfield.modify",
    "page": "Home",
    "title": "Setfield.modify",
    "category": "function",
    "text": "modify(f, l::Lens, obj)\n\nReplace a deeply nested part x of obj by f(x). See also Lens.\n\n\n\n"
},

{
    "location": "index.html#Setfield.set",
    "page": "Home",
    "title": "Setfield.set",
    "category": "function",
    "text": "set(l::Lens, obj, val)\n\nReplace a deeply nested part of obj by val. See also Lens.\n\n\n\n"
},

{
    "location": "index.html#Setfield.@lens-Tuple{Any}",
    "page": "Home",
    "title": "Setfield.@lens",
    "category": "macro",
    "text": "@lens\n\nConstruct a lens from a field access.\n\nExample\n\njulia> using Setfield\n\njulia> struct T;a;b;end\n\njulia> t = T(\"A1\", T(T(\"A3\", \"B3\"), \"B2\"))\nT(\"A1\", T(T(\"A3\", \"B3\"), \"B2\"))\n\njulia> l = @lens _.b.a.b\n(@lens _.b.a.b)\n\njulia> get(l, t)\n\"B3\"\n\njulia> set(l, t, 100)\nT(\"A1\", T(T(\"A3\", 100), \"B2\"))\n\njulia> t = (\"one\", \"two\")\n(\"one\", \"two\")\n\njulia> set((@lens _[1]), t, \"1\")\n(\"1\", \"two\")\n\n\n\n"
},

{
    "location": "index.html#Setfield.@set!-Tuple{Any}",
    "page": "Home",
    "title": "Setfield.@set!",
    "category": "macro",
    "text": "@set! assignment\n\nUpdate deeply nested parts of an object. In contrast to @set, @set! overwrites the variable binding and mutates the original object if possible. \n\njulia> using Setfield\n\njulia> struct T;a;b end\n\njulia> t = T(1,2)\nT(1, 2)\n\njulia> @set! t.a = 5\nT(5, 2)\n\njulia> t\nT(5, 2)\n\njulia> @set t.a = 10\nT(10, 2)\n\njulia> t\nT(5, 2)\n\nWarning\n\nSince @set! rebinds the variable, it will cause type instabilites for updates that change the type.\n\nSee also @set.\n\n\n\n"
},

{
    "location": "index.html#Setfield.@set-Tuple{Any}",
    "page": "Home",
    "title": "Setfield.@set",
    "category": "macro",
    "text": "@set assignment\n\nReturn a modified copy of deeply nested objects.\n\nExample\n\njulia> using Setfield\n\njulia> struct T;a;b end\n\njulia> t = T(1,2)\nT(1, 2)\n\njulia> @set t.a = 5\nT(5, 2)\n\njulia> t\nT(1, 2)\n\njulia> t = @set t.a = T(2,2)\nT(T(2, 2), 2)\n\njulia> @set t.a.b = 3\nT(T(2, 3), 2)\n\nSee also @set!.\n\n\n\n"
},

{
    "location": "index.html#Docstrings-1",
    "page": "Home",
    "title": "Docstrings",
    "category": "section",
    "text": "Modules = [Setfield]"
},

]}
