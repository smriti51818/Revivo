"""Standard API Gateway responses with CORS and Decimal-safe JSON."""
import json
from decimal import Decimal

_CORS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
}


class _DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            return int(o) if o % 1 == 0 else float(o)
        return super().default(o)


def respond(status: int, body: dict) -> dict:
    return {
        "statusCode": status,
        "headers": _CORS,
        "body": json.dumps(body, cls=_DecimalEncoder),
    }


def ok(status: int, data: dict) -> dict:
    return respond(status, data)


def error(status: int, message: str) -> dict:
    return respond(status, {"error": message})
