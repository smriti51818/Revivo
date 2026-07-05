"""Cognito Pre-Sign-up trigger.

Auto-confirms new users and auto-verifies their email so sign-up is instant
(no emailed confirmation code) — a smooth first-run for the pilot and demo.
"""


def handler(event, context):
    event["response"]["autoConfirmUser"] = True
    attrs = event.get("request", {}).get("userAttributes", {})
    if attrs.get("email"):
        event["response"]["autoVerifyEmail"] = True
    return event
