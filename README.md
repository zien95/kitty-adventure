# Kitty Adventure

Cozy virtual cat game with pet care, mini-games, secrets, rewards, and moon-garden vibes. 🐱🌙

[Play the web version](https://kitty-adventure-zona.web.app/)

## About

Kitty Adventure is a virtual pet game where you adopt cats, care for them, play mini-games, unlock secrets, and build a little cat family. Feed, clean, train, bond, heal, and spoil your cats while collecting coins, rewards, rooms, outfits, and easter eggs.

## Features

- Adopt and manage multiple cats in the Cat Manager Center.
- Edit cat profiles with personality, favorite food, favorite toy, and bio.
- Care for stats like Health, Hunger, Happy, Energy, Clean, IQ, SOC, Bond, Sleep, and Level.
- Play mini-games including Racing, Puzzle, Puzzle Master, Quiz, Rhythm, Memory, and more.
- Send cats on timed jobs for coins, gems, XP, and care boosts.
- Equip rooms and outfits for bonuses.
- Enter secret codes like `MEOW2026`, `NAPKING`, `ANNIVERSARY3`, and `EGGHUNT`.
- Track discovered secrets in the Easter Egg Journal.
- Switch between light mode and dark mode.
- Enjoy the 3rd Anniversary banner and silly hidden easter eggs.

## Latest

Version `26.8.3` focuses on the new Kitty Adventure look:

- New moon-garden visual theme.
- More realistic cat and garden art.
- Cleaner top UI and stats layout.
- Cat Manager Center polish.
- Bug fixes and layout improvements.

## How To Play

- Use **Food** when Hunger gets high.
- Use **Toy** to raise happiness.
- Use **Clean** to restore cleanliness.
- Use **Sleep** to recover energy and health.
- Use **Train** to raise IQ and progress.
- Use **Bond** to grow friendship.
- Use **Medicine** and **Vaccine** for extra care.
- Open **Shop / Kitty Hub** for jobs, rooms, outfits, eggs, codes, and mini-games.
- Use **Manage** to adopt, rename, switch, and profile your cats.

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

Add your license here before publishing if you want people to reuse, remix, or contribute to the project.

