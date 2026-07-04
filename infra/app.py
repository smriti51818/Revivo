#!/usr/bin/env python3
"""Revivo — AWS CDK application entrypoint.

Defines every cloud resource so the entire backend deploys with `cdk deploy`.
Stacks are intentionally small and composable:

    DataStack   -> DynamoDB single table (Streams + TTL) + S3 upload bucket
    AuthStack   -> Cognito user pool (custom:role) + app client
    ApiStack    -> API Gateway (REST) + Cognito authorizer + Lambda integrations

Event orchestration (Step Functions, EventBridge, SNS) is added in later
modules as MessagingStack / EventsStack.
"""
import aws_cdk as cdk

from stacks.api_stack import ApiStack
from stacks.auth_stack import AuthStack
from stacks.data_stack import DataStack

app = cdk.App()

data = DataStack(app, "Revivo-Data")
auth = AuthStack(app, "Revivo-Auth")
ApiStack(
    app,
    "Revivo-Api",
    table=data.table,
    uploads_bucket=data.uploads_bucket,
    user_pool=auth.user_pool,
)

cdk.Tags.of(app).add("project", "revivo")
app.synth()
