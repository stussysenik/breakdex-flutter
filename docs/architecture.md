# Breakdex Architecture

## Entity Relationship Diagram

```mermaid
erDiagram
    MOVES ||--o| FSRS_CARDS : "1:1 scheduling"
    MOVES ||--o{ REVIEWS : "1:N history"
    MOVES }o--|| CATEGORIES : "belongs to"
    COMBOS ||--o{ COMBO_MOVES : "has sequence"
    COMBO_MOVES }o--|| MOVES : "references"
    BATTLE_RESULTS ||--o{ MOVES : "reviews"
    SYNC_LOG ||--o| MOVES : "tracks changes"
    SYNC_LOG ||--o| COMBOS : "tracks changes"
    SYNC_LOG ||--o| REVIEWS : "tracks changes"

    MOVES {
        text id PK
        text name
        text learningState "NEW|LEARNING|MASTERY (legacy)"
        text category
        text videoPath
        datetime createdAt
    }

    FSRS_CARDS {
        text moveId PK_FK
        real stability "memory strength"
        real difficulty "item difficulty 0-10"
        datetime due "next review date"
        datetime lastReview
        int reps "consecutive correct"
        int lapses "times forgotten"
        int fsrsState "0=New 1=Learning 2=Review 3=Relearning"
    }

    REVIEWS {
        text id PK
        text rating "AGAIN|HARD|GOOD|EASY"
        text reviewType "MOVE|COMBO|MANUAL"
        datetime reviewedAt
        text moveId FK
    }

    CATEGORIES {
        text name PK
        int colorValue
    }
```

## FSRS State Machine

```mermaid
stateDiagram-v2
    [*] --> New: Card created
    New --> Learning: First review (any rating)
    Learning --> Learning: Again / Hard
    Learning --> Review: Good / Easy (graduated)
    Review --> Review: Good / Easy (interval grows)
    Review --> Relearning: Again (lapsed)
    Relearning --> Relearning: Again / Hard
    Relearning --> Review: Good / Easy (re-graduated)
```

## Data Flow

```mermaid
flowchart TB
    subgraph Presentation["Presentation Layer"]
        PS[MasteryPrescreen]
        FC[FlashcardReviewScreen]
        SS[StatsScreen]
        RD[ReviewDashboard]
    end

    subgraph State["State Layer (Riverpod)"]
        RP[reviewSessionActiveProvider]
        FRP[filteredReviewMovesProvider]
        CMP[categoryMasteryProvider]
        SBP[statsBundleProvider]
        DCP[dueCardCountProvider]
    end

    subgraph Data["Data Layer"]
        FS[FsrsService]
        MR[MoveRepository]
        RR[ReviewRepository]
    end

    subgraph Storage["Storage Layer"]
        DB[(SQLite / Drift)]
        SB[(Supabase Cloud)]
    end

    PS --> RP & CMP & DCP
    FC --> FRP & FS
    SS --> SBP
    RD --> FRP

    RP --> FS
    FRP --> MR & FS
    CMP --> FS
    SBP --> RR & FS
    DCP --> FS

    FS --> DB
    MR --> DB
    RR --> DB
    DB <-->|sync| SB
```

## Review Flow Sequence

```mermaid
sequenceDiagram
    actor User
    participant PS as MasteryPrescreen
    participant FS as FsrsService
    participant FC as FlashcardReview
    participant DB as Database

    User->>PS: Opens Review tab
    PS->>FS: getCategoryMastery()
    FS->>DB: JOIN fsrs_cards + moves
    DB-->>FS: cards with moves
    FS-->>PS: CategoryMastery per category
    PS->>FS: getDueCards()
    FS-->>PS: due count
    PS-->>User: Shows mastery grid + due counts

    User->>PS: Taps "Start" on category
    PS->>FC: Set category filter + sessionActive=true
    FC->>FS: getDueCards(category)
    FS-->>FC: filtered due moves
    FC-->>User: Shows first flashcard

    User->>FC: Rates card (Good)
    FC->>DB: Insert review record
    FC->>FS: processReview(moveId, "GOOD")
    FS->>DB: Update fsrs_cards (new due, stability, difficulty)
    FS-->>FC: next due date
    FC-->>User: Shows next card

    User->>FC: Completes session
    FC->>FC: sessionActive = false
    FC-->>User: Returns to MasteryPrescreen
```
