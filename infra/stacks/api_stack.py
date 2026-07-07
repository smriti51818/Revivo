"""ApiStack — REST API with a Cognito authorizer and Lambda integrations."""
import os

from aws_cdk import (
    CfnOutput,
    Duration,
    Stack,
    aws_apigateway as apigw,
    aws_cognito as cognito,
    aws_dynamodb as dynamodb,
    aws_iam as iam,
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

        # Freshness analysis preview — pure compute, no table access.
        analyze_listing_fn = self._fn(
            "AnalyzeListingFn", "analyze_listing", common_env, use_shared=True
        )

        # Update stock (owner-only quantity change).
        update_listing_fn = self._fn(
            "UpdateListingFn", "update_listing", common_env, use_shared=True
        )
        table.grant_read_write_data(update_listing_fn)

        # Seller insights — real metrics + Bedrock (Amazon Nova) recommendations.
        seller_insights_fn = self._fn(
            "SellerInsightsFn",
            "seller_insights",
            {
                **common_env,
                "BEDROCK_MODEL_ID": "apac.amazon.nova-micro-v1:0",
            },
            use_shared=True,
        )
        table.grant_read_data(seller_insights_fn)
        seller_insights_fn.add_to_role_policy(
            iam.PolicyStatement(
                actions=["bedrock:InvokeModel", "bedrock:Converse"],
                resources=[
                    "arn:aws:bedrock:*::foundation-model/*",
                    "arn:aws:bedrock:*:*:inference-profile/*",
                ],
            )
        )

        # Amazon Rekognition — identify the vegetable from the uploaded photo.
        identify_fn = self._fn(
            "IdentifyVegetableFn", "identify_vegetable", common_env,
            use_shared=True,
        )
        uploads_bucket.grant_read(identify_fn)
        identify_fn.add_to_role_policy(
            iam.PolicyStatement(
                actions=["rekognition:DetectLabels"],
                resources=["*"],
            )
        )

        create_order_fn = self._fn(
            "CreateOrderFn", "create_order", common_env, use_shared=True
        )
        table.grant_read_write_data(create_order_fn)

        my_orders_fn = self._fn(
            "MyOrdersFn", "list_my_orders", common_env, use_shared=True
        )
        table.grant_read_data(my_orders_fn)

        # Buyer rates a completed order (quality feedback on the vendor).
        rate_order_fn = self._fn(
            "RateOrderFn", "rate_order", common_env, use_shared=True
        )
        table.grant_read_write_data(rate_order_fn)

        # Vendor manually advances fulfilment (mark ready / handed over).
        advance_order_fn = self._fn(
            "AdvanceOrderFn", "advance_order", common_env, use_shared=True
        )
        table.grant_read_write_data(advance_order_fn)

        # Seller-side view: orders placed against this vendor's listings.
        vendor_orders_fn = self._fn(
            "VendorOrdersFn", "list_vendor_orders", common_env, use_shared=True
        )
        table.grant_read_data(vendor_orders_fn)

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

        # M8 — Bedrock (Amazon Nova) "why rescue this?" explanations.
        explain_rescue_fn = self._fn(
            "ExplainRescueFn",
            "explain_rescue",
            {
                **common_env,
                "BEDROCK_MODEL_ID": "apac.amazon.nova-micro-v1:0",
            },
            use_shared=True,
        )
        table.grant_read_data(explain_rescue_fn)
        explain_rescue_fn.add_to_role_policy(
            iam.PolicyStatement(
                actions=["bedrock:InvokeModel", "bedrock:Converse"],
                resources=[
                    "arn:aws:bedrock:*::foundation-model/*",
                    "arn:aws:bedrock:*:*:inference-profile/*",
                ],
            )
        )

        impact_fn = self._fn(
            "ImpactFn", "impact", common_env, use_shared=True
        )
        table.grant_read_data(impact_fn)

        # Persisted profile aggregates (wallet balance, vendor reputation,
        # buyer/cook stats) — replaces the client-side faked numbers.
        profile_fn = self._fn(
            "GetProfileFn", "get_profile", common_env, use_shared=True
        )
        table.grant_read_data(profile_fn)

        # Cook logs meals served for a delivered rescue (Transform-stage proof).
        log_meal_fn = self._fn(
            "LogMealFn", "log_meal", common_env, use_shared=True
        )
        table.grant_read_write_data(log_meal_fn)

        # M6 — in-app notification feed (written by the notifier in the
        # NotificationStack; read + marked-read here).
        list_notifications_fn = self._fn(
            "ListNotificationsFn", "list_notifications", common_env,
            use_shared=True,
        )
        table.grant_read_data(list_notifications_fn)

        mark_read_fn = self._fn(
            "MarkNotificationsReadFn", "mark_notifications_read", common_env,
            use_shared=True,
        )
        table.grant_read_write_data(mark_read_fn)

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
        self._protected(
            listings.add_resource("analyze"), "POST", analyze_listing_fn
        )
        self._protected(
            listings.add_resource("identify"), "POST", identify_fn
        )
        self._protected(
            listings.add_resource("insights"), "GET", seller_insights_fn
        )
        self._protected(
            listings.add_resource("{listingId}"), "PATCH", update_listing_fn
        )

        orders = api.root.add_resource("orders")
        self._protected(orders, "POST", create_order_fn)
        self._protected(orders, "GET", my_orders_fn)
        self._protected(
            orders.add_resource("incoming"), "GET", vendor_orders_fn
        )
        order_item = orders.add_resource("{orderId}")
        self._protected(order_item.add_resource("rate"), "POST", rate_order_fn)
        self._protected(
            order_item.add_resource("status"), "POST", advance_order_fn
        )

        rescues = api.root.add_resource("rescues")
        self._protected(rescues, "POST", create_rescue_fn)
        self._protected(rescues, "GET", list_rescues_fn)
        rescue_item = rescues.add_resource("{rescueId}")
        self._protected(rescue_item, "POST", transition_rescue_fn)
        self._protected(
            rescue_item.add_resource("explain"), "POST", explain_rescue_fn
        )
        self._protected(
            rescue_item.add_resource("meals"), "POST", log_meal_fn
        )

        self._protected(api.root.add_resource("impact"), "GET", impact_fn)
        self._protected(api.root.add_resource("profile"), "GET", profile_fn)

        notifications = api.root.add_resource("notifications")
        self._protected(notifications, "GET", list_notifications_fn)
        self._protected(
            notifications.add_resource("read"), "POST", mark_read_fn
        )

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
