# backend/ — Lambda handlers (Python 3.12)

Business logic for Revivo. Each function is a small, idempotent handler; shared code lives in
`shared/`.

## Layout (planned)
```
backend/
├── functions/
│   ├── create_listing/      # presigned upload result → listing + freshness band
│   ├── get_listings/        # buyer feed (nearby + aggregated)
│   ├── place_order/         # one-tap order
│   ├── match_buyers/        # DynamoDB Streams → relevance score → SNS
│   ├── recalc_freshness/    # EventBridge → band re-evaluation
│   ├── rescue_engine/       # matching filters → rescue routing
│   ├── bedrock_explain/     # human-readable rescue explanations
│   └── record_meals/        # cook workflow → impact aggregates
├── shared/                  # dynamo client, models, shelf_life.json, validators
└── requirements.txt
```

## Conventions
- Handlers are idempotent; DynamoDB conditional writes prevent duplicates.
- Inputs validated + sanitized before any write.
- Shelf-life DB is loaded once into warm Lambda memory.
