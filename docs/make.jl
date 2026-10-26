using Setfield, Documenter, Literate

inputdir = joinpath(@__DIR__, "..", "examples")
outputdir = joinpath(@__DIR__, "src", "examples")
mkpath(outputdir)
for filename in readdir(inputdir)
    inpath = joinpath(inputdir, filename)
    Literate.markdown(inpath, outputdir; documenter=true)
end

makedocs(
         modules = [Setfield],
         sitename = "Setfield.jl",
         pages = [
            "Introduction" => "intro.md",
            "Docstrings" => "index.md",
            "Custom Macros" => "examples/custom_macros.md",
             hide("internals.md"),
            ],
        )

deploydocs(
    repo = "github.com/jw3126/Setfield.jl.git",
)
