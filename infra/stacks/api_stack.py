"""ApiStack — REST API with a Cognito authorizer and Lambda integrations."""
import os

from aws_cdk import (
    CfnOutput,
    Duration,
    Stack,
    aws_apigateway as apigw,
    aws_cognito as cognito,
    aws_dynamodb as dynamodb,
    aws_lambda as lambda_,
    aws_s3 as s3,
)
from constructs import Construct

from .shared_layer import build_shared_layer

# Repo-root-relative path to the Lambda source.
_BACKEND = os.path.join(
    os.path.dirname(__file__), "..", "..", "backend", "functions"
)


class ApiStack(Stack):
    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        *,
        table: dynamodb.Table,
        uploads_bucket: s3.Bucket,
        user_pool: cognito.UserPool,
        **kwargs,
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)

        self.shared_layer = build_shared_layer(self)
        common_env = {
            "TABLE_NAME": table.table_name,
            "UPLOADS_BUCKET": uploads_bucket.bucket_name,
        }

        # ─── Lambda functions ───────────────────────────────────────
        health_fn = self._fn("HealthFn", "health", common_env)
        table.grant_read_data(health_fn)

        whoami_fn = self._fn("WhoAmIFn", "whoami", common_env)

        create_listing_fn = self._fn(
            "CreateListingFn", "create_listing", common_env, use_shared=True
        )
        table.grant_read_write_data(create_listing_fn)
        uploads_bucket.grant_read(create_listing_fn)

        list_listings_fn = self._fn(
            "ListListingsFn", "list_listings", common_env, use_shared=True
        )
        table.grant_read_data(list_listings_fn)
        uploads_bucket.grant_read(list_listings_fn)

        my_listings_fn = self._fn(
            "MyListingsFn", "list_my_listings", common_env, use_shared=True
        )
        table.grant_read_data(my_listings_fn)
        uploads_bucket.grant_read(my_listings_fn)

        create_order_fn = self._fn(
            "CreateOrderFn", "create_order", common_env, use_shared=True
        )
        table.grant_read_write_data(create_order_fn)

        my_orders_fn = self._fn(
            "MyOrdersFn", "list_my_orders", common_env, use_shared=True
        )
        table.grant_read_data(my_orders_fn)

        create_rescue_fn = self._fn(
            "CreateRescueFn", "create_rescue", common_env, use_shared=True
        )
        table.grant_read_write_data(create_rescue_fn)

        list_rescues_fn = self._fn(
            "ListRescuesFn", "list_rescues", common_env, use_shared=True
        )
        table.grant_read_data(list_rescues_fn)

        transition_rescue_fn = self._fn(
            "TransitionRescueFn", "transition_rescue", common_env, use_shared=True
        )
        table.grant_read_write_data(transition_rescue_fn)

        impact_fn = self._fn(
            "ImpactFn", "impact", common_env, use_shared=True
        )
        table.grant_read_data(impact_fn)

        upload_fn = self._fn(
            "CreateUploadUrlFn", "create_upload_url", common_env, use_shared=True
        )
        uploads_bucket.grant_put(upload_fn)

        # ─── REST API ───────────────────────────────────────────────
        api = apigw.RestApi(
            self,
            "RevivoApi",
            rest_api_name="revivo-api",
            description="Revivo REST API",
            default_cors_preflight_options=apigw.CorsOptions(
                allow_origins=apigw.Cors.ALL_ORIGINS,
                allow_methods=apigw.Cors.ALL_METHODS,
                allow_headers=apigw.Cors.DEFAULT_HEADERS,
            ),
            deploy_options=apigw.StageOptions(
                stage_name="prod",
                throttling_rate_limit=50,
                throttling_burst_limit=20,
            ),
        )

        self.authorizer = apigw.CognitoUserPoolsAuthorizer(
            self, "Authorizer", cognito_user_pools=[user_pool]
        )

        # Public
        api.root.add_resource("health").add_method(
            "GET", apigw.LambdaIntegration(health_fn)
        )

        # Protected (Cognito JWT)
        self._protected(api.root.add_resource("me"), "GET", whoami_fn)

        listings = api.root.add_resource("listings")
        self._protected(listings, "POST", create_listing_fn)
        self._protected(listings, "GET", list_listings_fn)
        self._protected(listings.add_resource("mine"), "GET", my_listings_fn)

        orders = api.root.add_resource("orders")
        self._protected(orders, "POST", create_order_fn)
        self._protected(orders, "GET", my_orders_fn)

        rescues = api.root.add_resource("rescues")
        self._protected(rescues, "POST", create_rescue_fn)
        self._protected(rescues, "GET", list_rescues_fn)
        self._protected(
            rescues.add_resource("{rescueId}"), "POST", transition_rescue_fn
        )

        self._protected(api.root.add_resource("impact"), "GET", impact_fn)

        self._protected(
            api.root.add_resource("uploads"), "POST", upload_fn
        )

        self.api = api
        CfnOutput(self, "ApiUrl", value=api.url)

    # ─── helpers ────────────────────────────────────────────────────
    def _fn(
        self,
        cid: str,
        folder: str,
        environment: dict,
        use_shared: bool = False,
    ) -> lambda_.Function:
        """Standard Python Lambda from backend/functions/<folder>."""
        return lambda_.Function(
            self,
            cid,
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="handler.handler",
            code=lambda_.Code.from_asset(os.path.join(_BACKEND, folder)),
            timeout=Duration.seconds(15),
            memory_size=256,
            environment=environment,
            layers=[self.shared_layer] if use_shared else None,
        )

    def _protected(
        self, resource: apigw.Resource, method: str, fn: lambda_.Function
    ) -> None:
        resource.add_method(
            method,
            apigw.LambdaIntegration(fn),
            authorizer=self.authorizer,
            authorization_type=apigw.AuthorizationType.COGNITO,
        )
