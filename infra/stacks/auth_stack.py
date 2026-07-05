"""AuthStack — Cognito user pool with role-based access."""
import os

from aws_cdk import (
    CfnOutput,
    Duration,
    RemovalPolicy,
    Stack,
    aws_cognito as cognito,
    aws_lambda as lambda_,
)
from constructs import Construct

_BACKEND = os.path.join(
    os.path.dirname(__file__), "..", "..", "backend", "functions"
)


class AuthStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Pre-sign-up trigger auto-confirms users + verifies email, so the
        # first run needs no emailed code — smooth for the pilot and demo.
        pre_signup_fn = lambda_.Function(
            self,
            "PreSignupFn",
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="handler.handler",
            code=lambda_.Code.from_asset(os.path.join(_BACKEND, "pre_signup")),
            timeout=Duration.seconds(10),
            memory_size=128,
        )

        # One pool for all four roles; `custom:role` carries the persona so
        # API Gateway + Lambda can authorize by role with zero custom code.
        self.user_pool = cognito.UserPool(
            self,
            "UserPool",
            user_pool_name="revivo-users",
            self_sign_up_enabled=True,
            sign_in_aliases=cognito.SignInAliases(email=True),
            auto_verify=cognito.AutoVerifiedAttrs(email=True),
            standard_attributes=cognito.StandardAttributes(
                email=cognito.StandardAttribute(required=True, mutable=True),
                fullname=cognito.StandardAttribute(required=False, mutable=True),
            ),
            custom_attributes={
                "role": cognito.StringAttribute(
                    min_len=1, max_len=20, mutable=True
                ),
            },
            password_policy=cognito.PasswordPolicy(
                min_length=8,
                require_lowercase=True,
                require_digits=True,
            ),
            account_recovery=cognito.AccountRecovery.EMAIL_ONLY,
            lambda_triggers=cognito.UserPoolTriggers(pre_sign_up=pre_signup_fn),
            removal_policy=RemovalPolicy.DESTROY,
        )

        # Explicitly grant the app client read + write on custom:role so it is
        # written at sign-up, returned in the ID token, and updatable — without
        # this the role claim can be missing and the app falls back to a
        # default persona.
        client_read = (
            cognito.ClientAttributes()
            .with_standard_attributes(
                email=True, email_verified=True, fullname=True
            )
            .with_custom_attributes("role")
        )
        client_write = (
            cognito.ClientAttributes()
            .with_standard_attributes(email=True, fullname=True)
            .with_custom_attributes("role")
        )

        self.user_pool_client = self.user_pool.add_client(
            "AppClient",
            user_pool_client_name="revivo-app",
            auth_flows=cognito.AuthFlow(
                user_password=True,
                user_srp=True,
            ),
            read_attributes=client_read,
            write_attributes=client_write,
            prevent_user_existence_errors=True,
        )

        CfnOutput(self, "UserPoolId", value=self.user_pool.user_pool_id)
        CfnOutput(
            self,
            "UserPoolClientId",
            value=self.user_pool_client.user_pool_client_id,
        )
