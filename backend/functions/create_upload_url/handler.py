"""POST /uploads — issue a short-lived presigned S3 PUT URL.

The vendor's device uploads the compressed photo directly to S3, bypassing API
Gateway and Lambda for a sub-second upload. The URL is scoped to the vendor's
folder and expires in 5 minutes.
"""
import os
import uuid

import boto3

from shared.responses import error, ok

_s3 = boto3.client("s3")
_BUCKET = os.environ["UPLOADS_BUCKET"]
_EXPIRY_SECONDS = 300


def handler(event, context):
    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("claims", {})
    )
    vendor_id = claims.get("sub", "demo-vendor")
    key = f"uploads/{vendor_id}/{uuid.uuid4().hex}.jpg"

    try:
        url = _s3.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": _BUCKET,
                "Key": key,
                "ContentType": "image/jpeg",
            },
            ExpiresIn=_EXPIRY_SECONDS,
        )
    except Exception as exc:  # noqa: BLE001 - surface as a clean API error
        return error(502, f"could not create upload url: {exc}")

    return ok(200, {"uploadUrl": url, "key": key, "expiresIn": _EXPIRY_SECONDS})
