"""DataStack — DynamoDB single table + S3 upload bucket."""
from aws_cdk import (
    CfnOutput,
    Duration,
    RemovalPolicy,
    Stack,
    aws_dynamodb as dynamodb,
    aws_s3 as s3,
)
from constructs import Construct


class DataStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # ─── Single-table design ────────────────────────────────────
        # PK/SK model all entities (users, listings, orders, rescues,
        # impact, cache). Streams drive matching + lifecycle; TTL is the
        # live freshness countdown.
        self.table = dynamodb.Table(
            self,
            "RevivoTable",
            table_name="RevivoTable",
            partition_key=dynamodb.Attribute(
                name="PK", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="SK", type=dynamodb.AttributeType.STRING
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            stream=dynamodb.StreamViewType.NEW_AND_OLD_IMAGES,
            time_to_live_attribute="ttl",
            removal_policy=RemovalPolicy.DESTROY,
        )

        # Overloaded GSIs for the app's access patterns.
        for i in (1, 2, 3):
            self.table.add_global_secondary_index(
                index_name=f"GSI{i}",
                partition_key=dynamodb.Attribute(
                    name=f"GSI{i}PK", type=dynamodb.AttributeType.STRING
                ),
                sort_key=dynamodb.Attribute(
                    name=f"GSI{i}SK", type=dynamodb.AttributeType.STRING
                ),
            )

        # ─── Image uploads (presigned, encrypted, short-lived) ──────
        self.uploads_bucket = s3.Bucket(
            self,
            "UploadsBucket",
            encryption=s3.BucketEncryption.S3_MANAGED,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            enforce_ssl=True,
            cors=[
                s3.CorsRule(
                    allowed_methods=[
                        s3.HttpMethods.PUT,
                        s3.HttpMethods.GET,
                        s3.HttpMethods.POST,
                    ],
                    allowed_origins=["*"],
                    allowed_headers=["*"],
                    max_age=3000,
                )
            ],
            lifecycle_rules=[s3.LifecycleRule(expiration=Duration.days(7))],
            removal_policy=RemovalPolicy.DESTROY,
            auto_delete_objects=True,
        )

        CfnOutput(self, "TableName", value=self.table.table_name)
        CfnOutput(self, "TableStreamArn", value=self.table.table_stream_arn or "")
        CfnOutput(self, "UploadsBucketName", value=self.uploads_bucket.bucket_name)
