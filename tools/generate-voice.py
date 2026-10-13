#!/usr/bin/env python3
"""
MindKlass — offline voice pre-generation (edge-tts)
===================================================================
WHY THIS EXISTS
-------------------------------------------------------------------
Both scripts you sent are Python and run on a SERVER or a PC. Neither
can run inside the MindKlass web app:

  * Bark is a ~5 GB PyTorch model. Browsers cannot run it, and cPanel
    shared hosting cannot either (no PyTorch, no GPU, no long-running
    Python process).
  * edge-tts is a Python client for Microsoft's read-aloud service. It
    also needs a server to run on.

So instead of synthesising speech live, this script generates the audio
ONCE, ahead of time, on your own Windows PC. You upload the resulting
MP3 files to your hosting, and the app plays them with a normal <audio>
element. That works on shared hosting, costs nothing per play, sounds
identical on every device (no more robotic Android voice), and keeps
working offline once cached.

HOW TO RUN IT (on your PC, once)
-------------------------------------------------------------------
    pip install edge-tts
    python generate-voice.py

Output lands in ./voice/ as MP3s plus a manifest.json index.
Upload the whole ./voice/ folder to public_html/voice/ on your host.

WHAT TO EDIT
-------------------------------------------------------------------
Replace the SEGMENTS list at the bottom with your real lesson text.
Each entry needs a stable id — the app uses it to find the file, so
never renumber existing ids, only append new ones.
"""

import asyncio
import json
import os
import re

import edge_tts

# ---------------------------------------------------------------------------
# Voice configuration — single female voice, as requested.
# The dual male/female switch is removed; there is one voice everywhere.
# Alternatives if you dislike Emma: "en-US-AvaNeural" (warmer, conversational)
# or "en-GB-SoniaNeural" (British, often preferred for IGCSE material).
# ---------------------------------------------------------------------------
VOICE = "en-US-EmmaMultilingualNeural"

# Energy presets. Keep these modest — heavy pitch shifts start to sound
# artificial again, which defeats the point.
ENERGY = {
    "high":   {"rate": "+15%", "pitch": "+10Hz"},   # excitement, achievements
    "normal": {"rate": "+0%",  "pitch": "+0Hz"},    # standard lesson narration
    "low":    {"rate": "-15%", "pitch": "-8Hz"},    # reflective, empathetic
}

OUT_DIR = "voice"


def slugify(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")[:60]


async def generate(segment_id: str, text: str, energy: str = "normal") -> dict:
    """Synthesise one segment to MP3 and return its manifest entry."""
    preset = ENERGY.get(energy, ENERGY["normal"])
    filename = f"{segment_id}.mp3"
    path = os.path.join(OUT_DIR, filename)

    communicate = edge_tts.Communicate(
        text, VOICE, rate=preset["rate"], pitch=preset["pitch"]
    )
    await communicate.save(path)

    size = os.path.getsize(path)
    print(f"  {filename:<40} {size/1024:7.1f} KB  ({energy})")
    return {
        "id": segment_id,
        "file": f"/{OUT_DIR}/{filename}",
        "energy": energy,
        "bytes": size,
        "chars": len(text),
    }


async def main(segments):
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f"Voice: {VOICE}")
    print(f"Generating {len(segments)} segments into ./{OUT_DIR}/\n")

    manifest = []
    for seg in segments:
        try:
            manifest.append(
                await generate(seg["id"], seg["text"], seg.get("energy", "normal"))
            )
        except Exception as exc:
            # One bad segment should not abort a long batch.
            print(f"  !! FAILED {seg['id']}: {exc}")

    with open(os.path.join(OUT_DIR, "manifest.json"), "w", encoding="utf-8") as fh:
        json.dump({"voice": VOICE, "segments": manifest}, fh, indent=2)

    total = sum(m["bytes"] for m in manifest)
    print(f"\nDone. {len(manifest)} files, {total/1024/1024:.1f} MB total.")
    print(f"Upload the ./{OUT_DIR}/ folder to public_html/{OUT_DIR}/ on your host.")


# ---------------------------------------------------------------------------
# REPLACE THIS with your real lesson segments.
# ---------------------------------------------------------------------------
SEGMENTS = [
    {
        "id": "lifeskills-w01-intro",
        "energy": "normal",
        "text": (
            "Welcome to Week One of the Life Skills Academy. Over the next fifty "
            "weeks you will build the habits, judgement and confidence that shape "
            "a life well lived. There are no written exams here. You will be "
            "assessed on projects, on discussion, and on what you actually do."
        ),
    },
    {
        "id": "lifeskills-w01-reflection",
        "energy": "low",
        "text": (
            "Before you continue, take a moment. Think about one decision you made "
            "this week that you would make differently now. Write it down. Growth "
            "begins with an honest look at yourself."
        ),
    },
    {
        "id": "lifeskills-w50-summit",
        "energy": "high",
        "text": (
            "This is it. The Grand Future Ready Summit. Fifty weeks of work come "
            "together today, and you are standing up to show what you have built."
        ),
    },
]


if __name__ == "__main__":
    asyncio.run(main(SEGMENTS))
