"""Generate original UI effects without overwriting licensed animal audio."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'sounds'
RATE = 22050
# MIDI notes with short rests between notes. Real pet recordings are processed
# separately by process_real_animal_sounds.py and must never be synthesized here.
PHRASES = {
    'click': [79], 'button_pop': [72, 79],
    'feed': [60, 64, 67], 'play': [72, 76, 79, 76],
    'clean': [79, 83, 86], 'sleep': [67, 64, 60],
    'train': [60, 62, 64, 67], 'medicine': [72, 76, 72],
    'level_up': [60, 64, 67, 72, 79], 'reward': [72, 76, 79, 84],
    'notification': [76, 72], 'secret_code': [60, 67, 70, 79],
}


def render(theme, notes):
    rng = random.Random(42)
    duration = {'cute': .105, 'soft': .14, 'arcade': .085}[theme]
    samples = []
    for midi in notes:
        frequency = 440 * 2 ** ((midi - 69) / 12)
        phase = 0.0
        count = int(RATE * duration)
        for i in range(count):
            t = i / RATE
            envelope = min(1.0, t / .008) * (1 - i / count) ** 1.8
            bend = 1 + (.13 * math.sin(math.pi * i / count) if theme == 'cute' else 0)
            phase += 2 * math.pi * frequency * bend / RATE
            if theme == 'arcade':
                tone = sum(math.sin(phase * n) / n for n in (1, 3, 5)) / 1.53
            elif theme == 'soft':
                tone = (math.sin(phase) + .22 * math.sin(phase * 2.01)) / 1.22
            else:
                tone = (math.sin(phase) + .3 * math.sin(phase * 2)
                        + .04 * rng.uniform(-1, 1)) / 1.34
            samples.append(int(16000 * tone * envelope))
        samples.extend([0] * int(RATE * .018))
    return struct.pack('<' + 'h' * len(samples), *samples)


if __name__ == '__main__':
    for theme in ('cute', 'soft', 'arcade'):
        folder = ROOT / theme
        folder.mkdir(exist_ok=True)
        for name, notes in PHRASES.items():
            with wave.open(str(folder / f'{name}.wav'), 'wb') as wav:
                wav.setnchannels(1)
                wav.setsampwidth(2)
                wav.setframerate(RATE)
                wav.writeframes(render(theme, notes))
    print(f'Generated {len(PHRASES) * 3} original WAV effects at {RATE} Hz.')
