"""Trim and normalize licensed real-animal recordings for Pet Fiasco.

Inputs must already be mono, 16-bit, 44.1 kHz PCM WAV files named after the
six species. Source downloads and licenses are documented in
THIRD_PARTY_AUDIO.md; this script deliberately does not download mutable URLs.
"""

from array import array
import argparse
from pathlib import Path
import shutil
import sys
import wave


RATE = 44_100
TARGET_SECONDS = {
    "cat": 1.45,
    "dog": 1.15,
    "bunny": 1.35,
    "fox": 1.60,
    "panda": 1.80,
    "bird": 1.05,
}
THEMES = ("cute", "soft", "arcade")


def read_mono_pcm(path: Path) -> array:
    with wave.open(str(path), "rb") as source:
        if (
            source.getnchannels() != 1
            or source.getsampwidth() != 2
            or source.getframerate() != RATE
        ):
            raise ValueError(f"{path} must be mono 16-bit {RATE} Hz PCM WAV")
        samples = array("h", source.readframes(source.getnframes()))
    if sys.byteorder != "little":
        samples.byteswap()
    return samples


def loudest_window(samples: array, seconds: float) -> tuple[int, array]:
    window = min(len(samples), round(seconds * RATE))
    if window == len(samples):
        return 0, samples

    hop = max(1, RATE // 20)
    best_start = 0
    best_energy = -1
    for start in range(0, len(samples) - window + 1, hop):
        energy = sum(sample * sample for sample in samples[start : start + window])
        if energy > best_energy:
            best_start = start
            best_energy = energy
    return best_start, samples[best_start : best_start + window]


def finish_clip(samples: array) -> array:
    if not samples:
        raise ValueError("The selected clip is empty")

    average = round(sum(samples) / len(samples))
    centered = array("h", (max(-32768, min(32767, s - average)) for s in samples))
    peak = max(abs(sample) for sample in centered)
    if peak == 0:
        raise ValueError("The selected clip contains only silence")

    target_peak = round(32767 * 0.78)
    gain = target_peak / peak
    normalized = array(
        "h",
        (max(-32768, min(32767, round(sample * gain))) for sample in centered),
    )

    fade = min(len(normalized) // 2, round(RATE * 0.02))
    for index in range(fade):
        scale = index / fade
        normalized[index] = round(normalized[index] * scale)
        normalized[-index - 1] = round(normalized[-index - 1] * scale)
    return normalized


def write_wav(path: Path, samples: array) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    output = array("h", samples)
    if sys.byteorder != "little":
        output.byteswap()
    with wave.open(str(path), "wb") as destination:
        destination.setnchannels(1)
        destination.setsampwidth(2)
        destination.setframerate(RATE)
        destination.writeframes(output.tobytes())


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_dir", type=Path)
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "assets" / "sounds",
    )
    args = parser.parse_args()

    for species, duration in TARGET_SECONDS.items():
        source = args.source_dir / f"{species}.wav"
        start, selected = loudest_window(read_mono_pcm(source), duration)
        clip = finish_clip(selected)
        output = args.output_dir / f"pet_{species}.wav"
        write_wav(output, clip)
        for theme in THEMES:
            themed = args.output_dir / theme / output.name
            themed.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(output, themed)

        if species == "cat":
            cat_meow = args.output_dir / "cat_meow.wav"
            shutil.copyfile(output, cat_meow)
            for theme in THEMES:
                shutil.copyfile(output, args.output_dir / theme / "cat_meow.wav")

        print(
            f"{species}: {len(clip) / RATE:.2f}s from {start / RATE:.2f}s "
            f"-> {output}"
        )


if __name__ == "__main__":
    main()
