# Pet Fiasco mobile Tauri shell

This project is intentionally for Android and iOS/iPadOS only. It loads the
hosted Pet Fiasco game from:

`https://pet-fiasco.web.app/?tauri-mobile=1`

The query marker tells the Flutter web app that it is inside the mobile shell.
In that mode, game content comes directly from Firebase Hosting, the web
Downloads chip is hidden, and the old native download-update prompt is skipped.

The shell grants the remote page no Tauri command capabilities. Native changes
to the shell still require a newly signed mobile build; hosted Flutter game
updates do not.

## Prerequisites

Follow the official Tauri v2 mobile prerequisites. On this Mac that includes a
Rust stable toolchain plus the Android and iOS Rust targets. Xcode, CocoaPods,
Android Studio, Node, and npm are already present.

## Install dependencies

```sh
npm install
npm run icons
```

The generated Android Studio and Xcode projects are checked in under
`src-tauri/gen/`. Run `npm run android:init` or `npm run ios:init` only when
regenerating those native projects from the Tauri configuration.

## Run or build

```sh
npm run android:dev
npm run ios:dev
npm run android:build
npm run ios:build
```

Do not use this shell for desktop builds. The existing Flutter targets remain
the desktop and ordinary web applications.
