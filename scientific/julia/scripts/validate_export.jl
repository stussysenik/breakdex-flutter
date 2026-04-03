using JSON3
using BreakdexScience

if length(ARGS) != 1
    error("Usage: julia --project=scientific/julia scientific/julia/scripts/validate_export.jl scientific/fixtures/sample_export.json")
end

payload = load_export(ARGS[1])
summary = summarize_export(payload)
println(JSON3.write(summary))
