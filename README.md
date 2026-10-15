# Pet Fiasco

Cozy virtual pet game with animal care, mini-games, secrets, rewards, and moon-garden vibes. 🐱🌙

[Play the web version](https://pet-fiasco.web.app/)

## About

Pet Fiasco is a virtual pet game where you adopt cute animals, care for them, play mini-games, unlock secrets, and build a little pet family. Feed, clean, train, bond, heal, and spoil your pets while collecting coins, rewards, rooms, outfits, and easter eggs.

## Features

- Adopt and manage multiple pets in the Pet Manager Center.
- Choose cats, dogs, bunnies, foxes, pandas, and birds.
- Edit pet profiles with type, personality, favorite food, favorite toy, and bio.
- Care for stats like Health, Hunger, Happy, Energy, Clean, IQ, SOC, Bond, Sleep, and Level.
- Play mini-games including Racing, Puzzle, Puzzle Master, Quiz, Rhythm, Memory, and more.
- Send pets on timed jobs for coins, gems, XP, and care boosts.
- Equip rooms and outfits for bonuses.
- Enter secret codes like `MEOW2026`, `NAPKING`, and `EGGHUNT`.
- Hatch a chosen species in Hub → Egg Nest after a saved two-minute countdown.
- Track hidden discoveries and clues in Hub → Secrets.
- Switch between light mode and dark mode.
- Discover hidden secrets with useful clues in Hub → Secrets.

## Latest

Version `26.9.1` is the Pet Fiasco update:

- Rebranded to Pet Fiasco at https://pet-fiasco.web.app.
- Added Firebase email/password accounts and private Firestore cloud saves in Settings.
- Added pet day counters, age in days, and a five-stage evolution journey.
- Pets evolve at ages 1, 3, 7, and 30 days, or levels 10, 20, 35, and 50.

- Added 57 original effects across Cute, Cozy, and Arcade sound themes.
- Added care sounds, pet voices, rewards, and navigation feedback throughout the game.
- Added effects/music volume controls, six music tracks, and mood-based music.
- Added the Care Journal with daily checklists, varied-care combos, and pet birthdays.
- Added care reaction bubbles and fixed tutorial startup and small-screen layouts.

Also includes the Pet Parade update:

- Added **Pet Parade** so the whole pet family can march together.
- Added the **Animal Almanac** with every species, habitat, and boost.
- Added habitat boosts for cats, dogs, bunnies, foxes, pandas, and birds.
- Added a visible daily streak card with tomorrow's reward preview.
- Added sound packs: Classic, Soft, Arcade, and Quiet.
- Balanced racing so high levels are fairer with tap spam or hold-space sprinting.
- Added clearer saved feedback and bug fixes for species labels.

## How To Play

- Use **Food** when Hunger gets high.
- Use **Toy** to raise happiness.
- Use **Clean** to restore cleanliness.
- Use **Sleep** to recover energy and health.
- Use **Train** to raise IQ and progress.
- Use **Bond** to grow friendship.
- Use **Medicine** and **Vaccine** for extra care.
- Open **Hub** for jobs, rooms, outfits, eggs, codes, and mini-games.
- Open **Hub → Almanac** to see animal habitat boosts.
- Open **Hub → Pet Parade** to watch your pets march.
- Use **Manage** to adopt, rename, switch, and profile your pets.

## Run Locally

Cloud accounts use the Firebase project `kitty-adventure-zona`. Deploy the owner-only
rules with `firebase deploy --only firestore:rules`. Enable Email/Password in Firebase
Authentication before account testing. Local play works without signing in.

When moving from the old web address, sign in there and choose **Use this device’s
progress** first. Then sign in at pet-fiasco.web.app and choose **Restore cloud
progress**. Browser storage belongs to each address, so cloud saves bridge the move.

```bash
flutter pub get
flutter run -d chrome
```

Build the web version:

```bash
flutter build web
```

Serve the built web app locally:

```bash
python3 -m http.server 8080 --directory build/web
```

Then open:

```text
http://127.0.0.1:8080/
```

## Project Notes

- Main game screen: `lib/screens/pet_game_screen.dart`
- Update checks: `lib/services/update_service.dart`
- Web files: `web/`
- Art, sound, and music assets: `assets/`
- Asset checklist: `assets/ASSETS.MD`

## Requirements

- Flutter SDK
- Dart SDK
- A modern browser for the web version
- Xcode / Android tooling only if building native apps

## Status

Pet Fiasco is actively evolving. Every update should keep the game cozy, playable, and at least slightly ridiculous. 😸✨

## License

Pet Fiasco is licensed under the GNU General Public License v3.0.

See [LICENSE](LICENSE) for the full license text.

Third-party animal recordings retain their stated licenses. See
[THIRD_PARTY_AUDIO.md](THIRD_PARTY_AUDIO.md) or open **Settings → Animal sound
credits** inside the game for creators, source pages, licenses, and documented
modifications.
