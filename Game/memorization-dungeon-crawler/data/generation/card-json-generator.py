#!/usr/bin/env python3
"""
make_cards_json.py

Scans generated clef note images and creates a cards.json file
for *natural notes*, applying "outer-bass" or "outer-treble" tags
to specified MIDI ranges.
"""

import os
import json
import argparse
import re

# =========================================================
# CONFIGURATION
# =========================================================
VALID_EXTENSIONS = {".png", ".jpg", ".jpeg"}
NATURAL_NOTES = {"A", "B", "C", "D", "E", "F", "G"}

# Define specific outer ranges (inclusive)
OUTER_RANGES = {
    "bass": [
        (24, 41),  # bass_024_C1 → bass_041_F2
        (59, 72),  # bass_059_B3 → bass_072_C5
    ],
    "treble": [
        (47, 59),  # treble_047_B2 → treble_059_B3
        (79, 96),  # treble_079_G5 → treble_096_C7
    ],
}

# =========================================================
# HELPERS
# =========================================================
def parse_image_filename(filename):
    """
    Expected format: clef_midi_note.png
    Example: bass_024_C1.png
    """
    match = re.match(r"(?P<clef>\w+)_(?P<midi>\d+)_(?P<note>[A-Ga-g]#?\d)\.png", filename)
    if not match:
        return None
    return match.groupdict()

def is_outer_tag(clef: str, midi: int) -> bool:
    """Return True if the note's MIDI is within one of the defined outer ranges."""
    clef = clef.lower()
    if clef not in OUTER_RANGES:
        return False
    for low, high in OUTER_RANGES[clef]:
        if low <= midi <= high:
            return True
    return False

# =========================================================
# MAIN
# =========================================================
def main():
    parser = argparse.ArgumentParser(description="Generate cards.json for natural note images with outer range tagging.")
    parser.add_argument("--images", required=True, help="Path to image folder")
    parser.add_argument("--out", default="cards.json", help="Output JSON filename")
    parser.add_argument("--web-prefix", default="/images", help="Path prefix for 'Question' field")
    args = parser.parse_args()

    cards = []

    for filename in sorted(os.listdir(args.images)):
        ext = os.path.splitext(filename)[1].lower()
        if ext not in VALID_EXTENSIONS:
            continue

        info = parse_image_filename(filename)
        if not info:
            continue

        clef = info["clef"].lower()
        midi = int(info["midi"])
        note = info["note"].upper()

        # skip sharps/flats
        if "#" in note or "B" in note and note[0] not in NATURAL_NOTES:
            continue
        if note[0] not in NATURAL_NOTES:
            continue

        # Determine tag
        if is_outer_tag(clef, midi):
            tag = f"outer-{clef}"
        else:
            tag = clef

        question_path = f"{args.web_prefix}/{filename}"
        card = {
            "Answer": note[0].lower(),
            "Question": question_path,
            "Tags": [tag],
            "Type": "image"
        }
        cards.append(card)

    data = {"Cards": cards}
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)

    print(f"✅ Generated {args.out} with {len(cards)} natural-note cards.")

if __name__ == "__main__":
    main()
