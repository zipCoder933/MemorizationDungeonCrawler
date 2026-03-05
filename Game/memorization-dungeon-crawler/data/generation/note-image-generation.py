#!/usr/bin/env python3
"""
generate_clef_notes.py

Generates single-note staff images for treble and bass clefs,
using clef images (treble-cleft.png and base-cleft.png) positioned
ON the staff with configurable offsets.

Example:
  python generate_clef_notes.py --clef treble --min-midi 48 --max-midi 84 --out treble_notes
  python generate_clef_notes.py --clef bass --min-midi 21 --max-midi 72 --out bass_notes
"""

import os
import argparse
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

# =========================================================
# CONFIG
# =========================================================
INVERT_CLEFTS = True  # If True, inverts clef image colors
BACKGROUND_COLOR = (0, 0, 0, 0)  # RGBA white
NOTE_STAFF_COLOR = (255,255,255)  # Black by default

IMG_W, IMG_H = 200, 200
MARGIN = 0
STAFF_LEFT = 0
LINE_SPACING = 12
STAFF_LINES = 5
STEP_HEIGHT = LINE_SPACING / 2

# Staff reference notes (bottom line)
CLEF_REFS = {
    "treble": 64,  # E4
    "bass": 43,    # G2
}

# Image placement offsets (x, y) for clef alignment on staff
TREBLE_CLEF_OFFSET = (70, -25)  # fine-tune until it sits right
BASS_CLEF_OFFSET   = (70, -35)

NOTE_OFFSET_X = -20

NOTE_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

try:
    FONT = ImageFont.truetype("DejaVuSans.ttf", 14)
except Exception:
    FONT = ImageFont.load_default()

# =========================================================
# HELPERS
# =========================================================
def midi_to_name(midi: int) -> str:
    octave = (midi // 12) - 1
    return f"{NOTE_NAMES[midi % 12]}{octave}"

def letter_index(midi: int) -> int:
    semitone_to_letter = {0:0,1:0,2:1,3:1,4:2,5:3,6:3,7:4,8:4,9:5,10:5,11:6}
    return semitone_to_letter[midi % 12]

def diatonic_distance(ref_midi: int, target_midi: int) -> int:
    ref_letter = letter_index(ref_midi)
    ref_oct = (ref_midi // 12) - 1
    tgt_letter = letter_index(target_midi)
    tgt_oct = (target_midi // 12) - 1
    return (tgt_oct - ref_oct) * 7 + (tgt_letter - ref_letter)

def draw_staff(draw, top_y, left_x):
    for i in range(STAFF_LINES):
        y = top_y + i * LINE_SPACING
        draw.line((left_x, y, IMG_W - MARGIN, y), fill=NOTE_STAFF_COLOR, width=2)

def draw_notehead(draw, x, y):
    w, h = 18, 12
    bbox = [x - w//2, y - h//2, x + w//2, y + h//2]
    draw.ellipse(bbox, fill=NOTE_STAFF_COLOR, outline=NOTE_STAFF_COLOR)

# =========================================================
# MAIN DRAWING FUNCTION
# =========================================================
def generate_note_image(clef: str, midi: int, out_path: str, show_name=False):
    img = Image.new("RGBA", (IMG_W, IMG_H), BACKGROUND_COLOR)
    draw = ImageDraw.Draw(img)

    # Load clef image
    clef_img_path = f"{BASE_DIR}/{clef}-cleft.png"
    # print("Loading clef image:", clef_img_path)

    if not os.path.exists(clef_img_path):
        raise FileNotFoundError(f"Missing {clef_img_path}")
    
    clef_img = Image.open(clef_img_path).convert("RGBA")
    if INVERT_CLEFTS:
        r, g, b, a = clef_img.split()
        rgb_inverted = Image.merge("RGB", (
            Image.eval(r, lambda p: 255 - p),
            Image.eval(g, lambda p: 255 - p),
            Image.eval(b, lambda p: 255 - p)
        ))
        clef_img = Image.merge("RGBA", (*rgb_inverted.split(), a))

    # Compute staff layout
    staff_height = (STAFF_LINES - 1) * LINE_SPACING
    staff_top_y = (IMG_H - staff_height) // 2
    staff_bottom_y = staff_top_y + staff_height
    draw_staff(draw, staff_top_y, STAFF_LEFT)

    # Determine clef offsets
    if clef == "treble":
        clef_offset = TREBLE_CLEF_OFFSET
        clef_scaled = clef_img.resize((50, 100))
    else:
        clef_offset = BASS_CLEF_OFFSET
        clef_scaled = clef_img.resize((43, 110))

    # Place clef on staff (centered vertically)
    clef_x = STAFF_LEFT - 65 + clef_offset[0]
    clef_y = staff_top_y + clef_offset[1]
    img.paste(clef_scaled, (clef_x, int(clef_y)), clef_scaled)

    # Compute note position
    ref_midi = CLEF_REFS[clef]
    pos_steps = diatonic_distance(ref_midi, midi)
    note_y = staff_bottom_y - (pos_steps * STEP_HEIGHT)
    note_x = STAFF_LEFT + NOTE_OFFSET_X + 140

    # Draw ledger lines if note is off-staff
    bottom_line_pos, top_line_pos = 0, 8
    if pos_steps < bottom_line_pos:
        for p in range(pos_steps, bottom_line_pos):
            if p % 2 == 0:
                y = staff_bottom_y - (p * STEP_HEIGHT)
                draw.line((note_x - 20, y, note_x + 20, y), fill=NOTE_STAFF_COLOR, width=2)
    elif pos_steps > top_line_pos:
        for p in range(top_line_pos + 1, pos_steps + 1):
            if p % 2 == 0:
                y = staff_bottom_y - (p * STEP_HEIGHT)
                draw.line((note_x - 20, y, note_x + 20, y), fill=NOTE_STAFF_COLOR, width=2)

    # Draw notehead and stem
    draw_notehead(draw, note_x, note_y)
    if pos_steps <= 4:
        draw.line((note_x + 9, note_y - 4, note_x + 9, note_y - 30), fill=NOTE_STAFF_COLOR, width=2)
    else:
        draw.line((note_x - 9, note_y + 4, note_x - 9, note_y + 30), fill=NOTE_STAFF_COLOR, width=2)

    # Optional label
    if show_name:
        name = midi_to_name(midi)
        draw.text((MARGIN, IMG_H - 20), f"{clef.upper()} {midi:03d} {name}", font=FONT, fill=NOTE_STAFF_COLOR)

    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    img.save(out_path, "PNG")

# =========================================================
# CLI ENTRY POINT
# =========================================================
def main():
    parser = argparse.ArgumentParser(description="Generate single-note staff images using clef PNGs on the staff.")
    parser.add_argument("--clef", choices=["treble", "bass"], required=True)
    parser.add_argument("--min-midi", type=int, default=11)
    parser.add_argument("--max-midi", type=int, default=108)
    parser.add_argument("--out", required=True)
    parser.add_argument("--show-name", action="store_true")
    args = parser.parse_args()

    os.makedirs(args.out, exist_ok=True)

    for midi in range(args.min_midi, args.max_midi + 1):
        name = midi_to_name(midi)
        out_path = os.path.join(args.out, f"{args.clef}_{midi:03d}_{name}.png")
        generate_note_image(args.clef, midi, out_path, args.show_name)
        print(f"✅ {out_path}")

if __name__ == "__main__":
    main()
