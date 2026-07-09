"""Presigned S3 GET URLs so the app can display private upload objects.

Signing is local (no network call), so enriching a page of listings is cheap.
Any failure degrades to an empty string — the client then shows its placeholder.
"""
import os

import boto3

_s3 = None


def _client():
    global _s3
    if _s3 is None:
        _s3 = boto3.client("s3")
    return _s3


def presigned_get_url(key: str, expires: int = 3600) -> str:
    bucket = os.environ.get("UPLOADS_BUCKET")
    if not key or not bucket:
        return ""
    try:
        return _client().generate_presigned_url(
            "get_object",
            Params={"Bucket": bucket, "Key": key},
            ExpiresIn=expires,
        )
    except Exception:  # noqa: BLE001 - display is best-effort
        return ""


def attach_image_url(listing: dict) -> dict:
    """Add a viewable `imageUrl` to a public listing.

    A real uploaded photo (`imageKey`) always wins, so when a seller changes a
    listing's photo the new image reflects immediately. Only when there is no
    `imageKey` do we fall back to a stored direct http(s) URL (legacy seed data).
    """
    key = listing.get("imageKey")
    if key:
        listing["imageUrl"] = presigned_get_url(key)
        return listing
    existing = listing.get("imageUrl")
    if existing and str(existing).startswith("http"):
        return listing
    listing["imageUrl"] = ""
    return listing
