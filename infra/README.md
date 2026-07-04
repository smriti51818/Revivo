# infra/ — AWS CDK (Python)

All Revivo cloud resources are defined here as code, so the entire backend deploys with a single
`cdk deploy`. This is the source of truth for infrastructure.

## Stacks (planned)
- **AuthStack** — Cognito user pool (`custom:role`), app client, identity pool.
- **DataStack** — DynamoDB single table (Streams + TTL), S3 upload bucket (SSE + CORS).
- **ApiStack** — API Gateway (REST) + Cognito authorizer + Lambda integrations + throttling.
- **EventsStack** — DynamoDB Streams consumers, EventBridge rules, Step Functions state machine.
- **MessagingStack** — SNS topic (push + SMS) + SQS dead-letter queue.

## Commands
```bash
make bootstrap      # one-time per account/region
make infra-deploy   # deploy all stacks
make infra-diff     # preview changes
make infra-destroy  # tear down
```
