from pathlib import Path

from breakdex_science.export_validation import load_export, summarize_export


FIXTURE = (
    Path(__file__).resolve().parents[2] / "fixtures" / "sample_export.json"
)


def test_sample_export_summary_matches_fixture() -> None:
    payload = load_export(FIXTURE)
    summary = summarize_export(payload)

    assert summary == {
        "schemaVersion": 7,
        "moveCount": 3,
        "activeMoveCount": 2,
        "archivedMoveCount": 1,
        "comboCount": 1,
        "reviewCount": 1,
        "battleResultCount": 1,
        "fsrsCardCount": 1,
        "deckCount": 1,
        "movesMissingVideo": ["move_002"],
        "activeStateCounts": {
            "LEARNING": 1,
            "NEW": 1,
        },
    }
