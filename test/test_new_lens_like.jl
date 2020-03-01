module TestNewLensLike

using Setfield
using Test

# SEC = SemanticEditorCombinator, see
# http://conal.net/blog/posts/semantic-editor-combinators
abstract type AbstractSEC <: Setfield.AbstractLensLike end

struct ComposedSEC{LO, LI} <: AbstractSEC
    outer::LO
    inner::LI
end

Setfield.compose(outer::AbstractSEC, inner::AbstractSEC) = ComposedSEC(outer, inner)
Setfield.compose(outer::AbstractSEC, inner::Lens) = ComposedSEC(outer, inner)
Setfield.compose(outer::Lens, inner::AbstractSEC) = ComposedSEC(outer, inner)

struct Constant{V}
    value::V
end
(o::Constant)(x) = o.value

function Setfield.set(obj, sec::AbstractSEC, value)
    modify(Constant(value), obj, sec)
end

function Setfield.modify(f, obj, sec::ComposedSEC)
    let sec=sec, f=f
        modify(obj, sec.outer) do inner_obj
            modify(f, inner_obj, sec.inner)
        end
    end
end

struct Elements <: AbstractSEC end
const elements = Elements()

function Setfield.modify(f, obj, ::Elements)
    map(f, obj)
end

@testset "Semantic editor combinators" begin
    # inspired by https://hackage.haskell.org/package/lens-tutorial-1.0.3/docs/Control-Lens-Tutorial.html
    molecule = (
        name="water",
        atoms=[
            (name="H", position=(x=1,y=1)),
            (name="H", position=(x=1,y=2)),
            (name="O", position=(x=1,y=3)),
        ]
    )

    se = @lens _.atoms ∘ $elements ∘ _.position.x
    res_modify = modify(x->x+1, molecule, se)

    res_macro = @set molecule.atoms ∘ $elements ∘ _.position.x += 1
    @test res_macro == res_modify

    res_expected = (
        name="water",
        atoms=[
            (name="H", position=(x=2,y=1)),
            (name="H", position=(x=2,y=2)),
            (name="O", position=(x=2,y=3)),
        ]
    )

    @test res_expected == res_macro

    res_set = set(molecule, se, 4.0)
    res_macro = @set molecule.atoms ∘ $elements ∘ _.position.x = 4.0
    @test res_macro == res_set

    res_expected = (
        name="water",
        atoms=[
            (name="H", position=(x=4.0,y=1)),
            (name="H", position=(x=4.0,y=2)),
            (name="O", position=(x=4.0,y=3)),
        ]
    )
    @test res_expected == res_set
end

end#module
