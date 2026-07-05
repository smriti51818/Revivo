"""NotificationStack — SNS topic + a Streams-driven notifier Lambda.

A new ORDER item notifies the seller (in-app feed item + SNS); a new RESCUE is
broadcast to the rescue-network topic. This is a second, independent consumer
of the table stream, running alongside the order-workflow starter.
"""
import os

from aws_cdk import (
    CfnOutput,
    Duration,
    Stack,
    aws_dynamodb as dynamodb,
    aws_lambda as lambda_,
    aws_lambda_event_sources as sources,
    aws_sns as sns,
)
from constructs import Construct

from .shared_layer import build_shared_layer

_BACKEND = os.path.join(
    os.path.dirname(__file__), "..", "..", "backend", "functions"
)


class NotificationStack(Stack):
    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        *,
        table: dynamodb.Table,
        **kwargs,
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)

        self.topic = sns.Topic(
            self,
            "NotificationsTopic",
            topic_name="revivo-notifications",
            display_name="Revivo",
        )

        notifier = lambda_.Function(
            self,
            "NotifierFn",
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="handler.handler",
            code=lambda_.Code.from_asset(os.path.join(_BACKEND, "notify")),
            timeout=Duration.seconds(30),
            memory_size=128,
            layers=[build_shared_layer(self)],
            environment={
                "TABLE_NAME": table.table_name,
                "TOPIC_ARN": self.topic.topic_arn,
            },
        )
        table.grant_read_write_data(notifier)
        self.topic.grant_publish(notifier)
        notifier.add_event_source(
            sources.DynamoEventSource(
                table,
                starting_position=lambda_.StartingPosition.LATEST,
                batch_size=5,
                retry_attempts=2,
            )
        )

        CfnOutput(
            self, "NotificationsTopicArn", value=self.topic.topic_arn
        )
