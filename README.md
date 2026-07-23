# Kitty Adventure

Cozy virtual pet game with animal care, mini-games, secrets, rewards, and moon-garden vibes. 🐱🌙

[Play the web version](https://kitty-adventure-zona.web.app/)

## About

Kitty Adventure is a virtual pet game where you adopt cute animals, care for them, play mini-games, unlock secrets, and build a little pet family. Feed, clean, train, bond, heal, and spoil your pets while collecting coins, rewards, rooms, outfits, and easter eggs.

## Features

- Adopt and manage multiple pets in the Pet Manager Center.
- Choose cats, dogs, bunnies, foxes, pandas, and birds.
- Edit pet profiles with type, personality, favorite food, favorite toy, and bio.
- Care for stats like Health, Hunger, Happy, Energy, Clean, IQ, SOC, Bond, Sleep, and Level.
- Play mini-games including Racing, Puzzle, Puzzle Master, Quiz, Rhythm, Memory, and more.
- Send pets on timed jobs for coins, gems, XP, and care boosts.
- Equip rooms and outfits for bonuses.
- Enter secret codes like `MEOW2026`, `NAPKING`, `ANNIVERSARY3`, and `EGGHUNT`.
- Track discovered secrets in the Easter Egg Journal.
- Switch between light mode and dark mode.
- Enjoy the 3rd Anniversary banner and silly hidden easter eggs.

## Latest

Version `26.8.5` refreshes every installable build with today's fixes:

- Made native and Lite Mode gameplay use the full heavy-web visuals.
- Added dog, bunny, fox, panda, and bird pets with 4K companion portraits.
- Added the in-game Next Move coach above the care buttons.
- Removed the Downloads button from installed app builds.
- Made room decor appear in the main gameplay scene.
- Updated Android, iPhone/iPad, macOS, and web downloads.
- Bug fixes.

## How To Play

- Use **Food** when Hunger gets high.
- Use **Toy** to raise happiness.
- Use **Clean** to restore cleanliness.
- Use **Sleep** to recover energy and health.
- Use **Train** to raise IQ and progress.
- Use **Bond** to grow friendship.
- Use **Medicine** and **Vaccine** for extra care.
- Open **Shop / Kitty Hub** for jobs, rooms, outfits, eggs, codes, and mini-games.
- Use **Manage** to adopt, rename, switch, and profile your pets.

## Run Locally

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

Kitty Adventure is actively evolving. Every update should keep the game cozy, playable, and at least slightly ridiculous. 😸✨

## License

Kitty Adventure is licensed under the GNU General Public License v3.0.

See [LICENSE](LICENSE) for the full license text.
