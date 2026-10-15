# Third-party animal audio

Pet Fiasco uses the following real-animal recordings. Attribution is included
for every creator, including CC0 and public-domain works where it is not legally
required. Source pages are the authority for each license.

| Animal | Recording and creator | Source | License |
| --- | --- | --- | --- |
| Cat | “Meow of a Siamese cat” by **freemaster2** | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Meow_of_a_Siamese_cat_-_freemaster2.wav) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| Dog | “Dog barking.wav” by **Ryding** | [Freesound #110134](https://freesound.org/people/Ryding/sounds/110134/) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| Bunny | “rabbit eating.wav” by **BeeProductive** | [Freesound #380890](https://freesound.org/people/BeeProductive/sounds/380890/) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| Fox | “Red Fox (Vulpes vulpes), W1CDR0001529 BD12,” recorded by **Aubrey John Williams**, supplied by **The British Library Board** | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Red_Fox_(Vulpes_vulpes)_(W1CDR0001529_BD12).ogg) | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) |
| Panda | “Giant panda twittering” by **Mizunoryu** | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Giant_panda_twittering.ogg) | Public domain dedication by the creator |
| Bird | “Bird chirp 2” by **Gravity Sound** | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Bird_chirp_2_(Gravity_Sound).mp3) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |

## Modifications

The bundled clips were excerpted from the recordings above, downmixed to mono,
resampled to 44.1 kHz, DC-centered, peak-normalized with headroom, faded at both
ends, and exported as 16-bit PCM WAV. Identical real-animal clips are used in
Classic, Cute, Soft, Arcade, and Quiet sound themes; the themes still affect the
other interface sounds and playback level.

The fox-derived files (`pet_fox.wav` in the base, Cute, Soft, and Arcade sound
folders) are adaptations distributed under **CC BY-SA 4.0**. All other clips
retain the license or public-domain status listed above. No creator or source
endorses Pet Fiasco.

## Source download hashes

These hashes identify the exact source or provider-generated preview/transcode
used for the processing pass on 2026-10-15:

```text
cat    c5ae80383913b599b697bdb03481807dce908b44497f68583183530c6490f9d4
dog    2319d1ead3cc9c198a7e91e5420b2c0a3918bd31fe126c24d3c672b17003f1c1
bunny  e3376d4e22b07cc21a8b17a88ee2142c12ff925049af86fa3b86dc1d2fa05c7a
fox    f12c1296907e92c3c7fc7c6f95207773163970b0f45e4445b4119228f0375f46
panda  7b60b528d8fba930e0a47adf10038f4c03d81f294d5a864109f792fb6858abc8
bird   c02c16b669322e3f0c35050a8a654c1ebc6ca31d3569e3069c4ccbc37efdc84e
```

Use `tools/process_real_animal_sounds.py` after decoding those sources to mono,
16-bit, 44.1 kHz PCM WAV files named `cat.wav`, `dog.wav`, `bunny.wav`,
`fox.wav`, `panda.wav`, and `bird.wav`.
