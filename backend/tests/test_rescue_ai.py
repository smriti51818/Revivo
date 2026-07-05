"""Unit tests for Bedrock rescue-explanation prompt building + fallback."""
from shared.rescue_ai import build_explain_body, fallback_explanation

_RESCUE = {
    "vegetable": "Tomatoes",
    "quantityKg": 8,
    "band": "RESCUE",
    "timeRange": "6-10 hours",
    "pickupArea": "Gandhipuram",
    "vendorName": "Green Farms",
}


def test_build_body_uses_bedrock_anthropic_schema():
    body = build_explain_body(_RESCUE)
    assert body["anthropic_version"] == "bedrock-2023-05-31"
    assert body["max_tokens"] > 0
    assert body["system"]
    assert body["messages"][0]["role"] == "user"


def test_build_body_includes_the_facts():
    content = build_explain_body(_RESCUE)["messages"][0]["content"]
    assert "Tomatoes" in content
    assert "8 kg" in content
    assert "20 meals" in content  # 8 / 0.4 = 20


def test_fallback_is_deterministic_and_grounded():
    text = fallback_explanation(_RESCUE)
    assert "Tomatoes" in text
    assert "20 meals" in text
    assert "landfill" in text.lower()
    assert "6-10 hours" in text


def test_fallback_handles_missing_fields():
    text = fallback_explanation({})
    assert isinstance(text, str) and text
