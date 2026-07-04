"""Builds a Lambda layer from backend/shared so every function can import it.

Stages `backend/shared` into `infra/.layer_build/python/shared` at synth time
(no Docker, no code duplication in git — the build dir is gitignored).
"""
import pathlib
import shutil

from aws_cdk import aws_lambda as lambda_
from constructs import Construct

_ROOT = pathlib.Path(__file__).resolve().parents[2]
_SRC = _ROOT / "backend" / "shared"
_BUILD_ROOT = _ROOT / "infra" / ".layer_build"


def build_shared_layer(scope: Construct) -> lambda_.LayerVersion:
    target = _BUILD_ROOT / "python" / "shared"
    if _BUILD_ROOT.exists():
        shutil.rmtree(_BUILD_ROOT)
    shutil.copytree(
        _SRC,
        target,
        ignore=shutil.ignore_patterns("__pycache__", "*.pyc"),
    )
    return lambda_.LayerVersion(
        scope,
        "SharedLayer",
        code=lambda_.Code.from_asset(str(_BUILD_ROOT)),
        compatible_runtimes=[lambda_.Runtime.PYTHON_3_12],
        description="Revivo shared code: freshness engine, models, validation.",
    )
