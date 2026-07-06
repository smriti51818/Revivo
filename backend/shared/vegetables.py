"""Canonical produce list + Amazon Rekognition label matching.

Rekognition returns generic labels (e.g. "Eggplant", "Bell Pepper"); we map the
highest-confidence produce label to one of Revivo's known vegetables so the app
can pre-select it. The seller can always override.
"""
from __future__ import annotations

# Display names shown in the app picker (also the values sent back to it).
VEGETABLES = [
    "Tomato", "Potato", "Onion", "Spinach", "Coriander", "Carrot",
    "Bell Pepper", "Cabbage", "Cauliflower", "Brinjal", "Okra",
    "Green Chilli", "Cucumber", "Beans", "Beetroot", "Radish",
    "Pumpkin", "Drumstick", "Curry Leaves", "Mint",
]

# Rekognition label (lowercased) -> Revivo display name.
_SYNONYMS: dict[str, str] = {
    "tomato": "Tomato",
    "potato": "Potato",
    "onion": "Onion",
    "shallot": "Onion",
    "spinach": "Spinach",
    "coriander": "Coriander",
    "cilantro": "Coriander",
    "parsley": "Coriander",
    "carrot": "Carrot",
    "bell pepper": "Bell Pepper",
    "capsicum": "Bell Pepper",
    "cabbage": "Cabbage",
    "cauliflower": "Cauliflower",
    "eggplant": "Brinjal",
    "aubergine": "Brinjal",
    "brinjal": "Brinjal",
    "okra": "Okra",
    "chili": "Green Chilli",
    "chilli": "Green Chilli",
    "chile": "Green Chilli",
    "jalapeno": "Green Chilli",
    "cucumber": "Cucumber",
    "zucchini": "Cucumber",
    "bean": "Beans",
    "green bean": "Beans",
    "beans": "Beans",
    "beet": "Beetroot",
    "beetroot": "Beetroot",
    "radish": "Radish",
    "daikon": "Radish",
    "pumpkin": "Pumpkin",
    "squash": "Pumpkin",
    "gourd": "Pumpkin",
    "drumstick": "Drumstick",
    "moringa": "Drumstick",
    "mint": "Mint",
    "peppermint": "Mint",
}


def match_vegetable(labels: list) -> str | None:
    """Given Rekognition labels (`[{"Name", "Confidence"}, ...]`, highest first),
    return the first matching produce display name, or None if nothing matches.
    """
    for label in labels or []:
        name = str(label.get("Name", "")).strip().lower()
        if name in _SYNONYMS:
            return _SYNONYMS[name]
    return None
