from __future__ import annotations

import json
from collections import Counter
from pathlib import Path
from typing import Any


def load_export(path: str | Path) -> dict[str, Any]:
    return json.loads(Path(path).read_text())


def summarize_export(payload: dict[str, Any]) -> dict[str, Any]:
    moves = payload.get("moves", [])
    combos = payload.get("combos", [])
    reviews = payload.get("reviews", [])
    battle_results = payload.get("battleResults", [])
    fsrs_cards = payload.get("fsrsCards", [])
    decks = payload.get("decks", [])

    active_moves = [move for move in moves if not move.get("archivedAt")]
    archived_moves = [move for move in moves if move.get("archivedAt")]
    missing_video_moves = [
        move["id"] for move in moves if not move.get("videoFilename")
    ]

    state_counts = Counter(
        (move.get("learningState") or "UNKNOWN") for move in active_moves
    )

    return {
        "schemaVersion": payload.get("schemaVersion"),
        "moveCount": len(moves),
        "activeMoveCount": len(active_moves),
        "archivedMoveCount": len(archived_moves),
        "comboCount": len(combos),
        "reviewCount": len(reviews),
        "battleResultCount": len(battle_results),
        "fsrsCardCount": len(fsrs_cards),
        "deckCount": len(decks),
        "movesMissingVideo": missing_video_moves,
        "activeStateCounts": dict(sorted(state_counts.items())),
    }
