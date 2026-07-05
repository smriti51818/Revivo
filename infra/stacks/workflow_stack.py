"""WorkflowStack — Step Functions order lifecycle driven by DynamoDB Streams.

When a new ORDER item is written, a stream-triggered Lambda starts a state
machine that advances the order through its fulfilment stages over time,
updating the item in place. No polling, no cron — pure event orchestration.
"""
import os

from aws_cdk import (
    CfnOutput,
    Duration,
    Stack,
    aws_dynamodb as dynamodb,
    aws_lambda as lambda_,
    aws_lambda_event_sources as sources,
    aws_stepfunctions as sfn,
    aws_stepfunctions_tasks as tasks,
)
from constructs import Construct

from .shared_layer import build_shared_layer

_BACKEND = os.path.join(
    os.path.dirname(__file__), "..", "..", "backend", "functions"
)

# Demo-friendly delays; each stage is ~15s so a full order completes in ~45s.
_STAGE_SECONDS = 15


class WorkflowStack(Stack):
    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        *,
        table: dynamodb.Table,
        **kwargs,
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)

        def set_status(label: str, status: str) -> tasks.DynamoUpdateItem:
            return tasks.DynamoUpdateItem(
                self,
                label,
                table=table,
                key={
                    "PK": tasks.DynamoAttributeValue.from_string(
                        sfn.JsonPath.string_at("$.pk")
                    ),
                    "SK": tasks.DynamoAttributeValue.from_string("META"),
                },
                update_expression="SET #s = :s",
                expression_attribute_names={"#s": "status"},
                expression_attribute_values={
                    ":s": tasks.DynamoAttributeValue.from_string(status),
                },
                # Keep the execution input ($.pk) for the following steps.
                result_path=sfn.JsonPath.DISCARD,
            )

        def wait(label: str) -> sfn.Wait:
            return sfn.Wait(
                self,
                label,
                time=sfn.WaitTime.duration(Duration.seconds(_STAGE_SECONDS)),
            )

        definition = (
            wait("PrepDelay")
            .next(set_status("MarkPreparing", "PREPARING"))
            .next(wait("ReadyDelay"))
            .next(set_status("MarkReady", "READY_FOR_PICKUP"))
            .next(wait("CompleteDelay"))
            .next(set_status("MarkCompleted", "COMPLETED"))
        )

        self.state_machine = sfn.StateMachine(
            self,
            "OrderLifecycle",
            state_machine_name="revivo-order-lifecycle",
            definition_body=sfn.DefinitionBody.from_chainable(definition),
            state_machine_type=sfn.StateMachineType.STANDARD,
            timeout=Duration.minutes(15),
        )

        # Stream processor: one execution per newly-inserted ORDER.
        starter = lambda_.Function(
            self,
            "StartOrderWorkflowFn",
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="handler.handler",
            code=lambda_.Code.from_asset(
                os.path.join(_BACKEND, "start_order_workflow")
            ),
            timeout=Duration.seconds(30),
            memory_size=128,
            layers=[build_shared_layer(self)],
            environment={
                "STATE_MACHINE_ARN": self.state_machine.state_machine_arn
            },
        )
        self.state_machine.grant_start_execution(starter)
        starter.add_event_source(
            sources.DynamoEventSource(
                table,
                starting_position=lambda_.StartingPosition.LATEST,
                batch_size=5,
                retry_attempts=2,
            )
        )

        CfnOutput(
            self,
            "OrderStateMachineArn",
            value=self.state_machine.state_machine_arn,
        )
