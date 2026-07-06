"""POST /listings/identify — identify the vegetable in an uploaded photo.

Runs Amazon Rekognition DetectLabels on the S3 object and maps the labels to
Revivo's produce list. Returns the best guess (or null) so the app can
pre-select it; the seller can always override.
"""
import json
import os

import boto3

from shared.responses import error, ok
from shared.vegetables import match_vegetable

_rek = None
_BUCKET = os.environ.get("UPLOADS_BUCKET", "")


def _client():
    global _rek
    if _rek is None:
        _rek = boto3.client("rekognition")
    return _rek


def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return error(400, "invalid JSON body")

    image_key = str(body.get("imageKey", "")).strip()
    if not image_key or not _BUCKET:
        return error(400, "imageKey is required")

    try:
        resp = _client().detect_labels(
            Image={"S3Object": {"Bucket": _BUCKET, "Name": image_key}},
            MaxLabels=15,
            MinConfidence=55,
        )
    except Exception as exc:  # noqa: BLE001 - surfaced as a clean API error
        return error(502, f"could not analyze image: {exc}")

    labels = resp.get("Labels", [])
    top = [
        {"name": lbl.get("Name"), "confidence": round(lbl.get("Confidence", 0), 1)}
        for lbl in labels[:6]
    ]
    return ok(200, {"vegetable": match_vegetable(labels), "labels": top})
