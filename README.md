# Pet Fiasco

Cozy virtual pet game with animal care, mini-games, secrets, rewards, and moon-garden vibes. 🐱🌙

[Play the web version](https://pet-fiasco.web.app/)

## About

Pet Fiasco is a virtual pet game where you adopt cute animals, care for them, play mini-games, unlock secrets, and build a little pet family. Feed, clean, train, bond, heal, and spoil your pets while collecting coins, rewards, rooms, outfits, and easter eggs.

## Features

- Adopt and manage multiple pets in the Pet Manager Center.
- Choose cats, dogs, bunnies, foxes, pandas, birds, and elephants.
- Explore a third-person garden with visible X/Y/Z coordinates on PC or mobile.
- Walk into the food bowl to eat, or jump and fly onto it.
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

Version `26.11.0` is **Exploration Update: Part 1**:

- Expanded the pet world to 72 by 90 world units with faster traversal.
- Added real illustrated destinations: Happy Paws Vet, Dreamy Bed, Toy Yard,
  Game Station, Duck Pond, Pet Cottage, Climbing Tree, Play Park, and Flower Garden.
- Press **E** on PC or **Action/Enter** on mobile near a destination to use it.
- Connected destinations to real care actions: healing, sleep, play, clean, train,
  bond, and the mini-games hub.
- Shows the pet family together; the selected pet is larger and tapping another
  pet switches control to it without resetting the exploration position.
- Kept nearby scenery anchored while the pet visibly walks through the world.
- Added the mobile-only Tauri shell for Android and iPadOS; it requires internet,
  loads hosted game updates automatically, and hides the web download button.

Also includes the `26.10.0` Third-Person Pet World update:

- Added a perspective 3D-style garden with real X/Y/Z simulation and camera orbit.
- Added WASD/arrow/Space/E controls plus a mobile joystick and action buttons.
- Birds can fly vertically; ground pets can walk into the bowl, and every pet can jump or land on it to eat.
- Added generated age- and mood-specific character artwork.
- Added elephants with a habitat bonus and a licensed real trumpet sound.
- Refreshed the first-run tour and Settings replay instructions.

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
- In the world, use **WASD** to move, **arrow keys** or drag to orbit, **Space**
  to jump/fly up, **Shift/Q** to fly down, and **E** to enter or act at a nearby place.

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
