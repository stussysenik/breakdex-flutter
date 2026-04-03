module BreakdexScience

using JSON3

export summarize_export, load_export

function load_export(path::AbstractString)
    return JSON3.read(read(path, String))
end

function summarize_export(payload)
    moves = get(payload, :moves, [])
    active_moves = [move for move in moves if isnothing(get(move, :archivedAt, nothing))]
    archived_moves = [move for move in moves if !isnothing(get(move, :archivedAt, nothing))]
    missing_video_moves = [
        String(get(move, :id, "")) for move in moves if isnothing(get(move, :videoFilename, nothing))
    ]

    state_counts = Dict{String, Int}()
    for move in active_moves
        state = String(get(move, :learningState, "UNKNOWN"))
        state_counts[state] = get(state_counts, state, 0) + 1
    end

    return Dict(
        "schemaVersion" => get(payload, :schemaVersion, nothing),
        "moveCount" => length(moves),
        "activeMoveCount" => length(active_moves),
        "archivedMoveCount" => length(archived_moves),
        "comboCount" => length(get(payload, :combos, [])),
        "reviewCount" => length(get(payload, :reviews, [])),
        "battleResultCount" => length(get(payload, :battleResults, [])),
        "fsrsCardCount" => length(get(payload, :fsrsCards, [])),
        "deckCount" => length(get(payload, :decks, [])),
        "movesMissingVideo" => missing_video_moves,
        "activeStateCounts" => Dict(sort(collect(state_counts))),
    )
end

end
