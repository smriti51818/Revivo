#!/usr/bin/env python3
"""Revivo — AWS CDK application entrypoint.

Defines every cloud resource so the entire backend deploys with `cdk deploy`.
Stacks are intentionally small and composable:

    DataStack         -> DynamoDB single table (Streams + TTL) + S3 upload bucket
    AuthStack         -> Cognito user pool (custom:role) + app client
    ApiStack          -> API Gateway (REST) + Cognito authorizer + Lambda integrations
    WorkflowStack     -> Step Functions order lifecycle, triggered by table Streams
    NotificationStack -> SNS topic + Streams-driven notifier (order/rescue alerts)
"""
import aws_cdk as cdk

from stacks.api_stack import ApiStack
from stacks.auth_stack import AuthStack
from stacks.data_stack import DataStack
from stacks.notification_stack import NotificationStack
from stacks.workflow_stack import WorkflowStack

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
WorkflowStack(app, "Revivo-Workflow", table=data.table)
NotificationStack(app, "Revivo-Notify", table=data.table)

cdk.Tags.of(app).add("project", "revivo")
app.synth()
