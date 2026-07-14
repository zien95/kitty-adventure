# Kitty Adventure Update Releases

## First-time setup

Run:

```bash
./setup_update_server.sh
```

The setup script:

- creates `~/KittyAdventureUpdates`,
- installs `ngrok` with Homebrew when needed,
- creates a macOS LaunchAgent helper,
- keeps the Mac awake while the server helper is enabled,
- starts the update file server,
- creates an HTTPS tunnel at the permanent ngrok dev domain,
- restarts the helper automatically if it crashes,
- starts the helper again whenever you log in,
- writes connection details to `UPDATE_SERVER_INFO.txt`.

Check it later with:

```bash
./setup_update_server.sh status
```

Stop or restart it with:

```bash
./setup_update_server.sh stop
./setup_update_server.sh restart
```

## Release an update

Just run:

```bash
./release_update.sh
```

The script asks for:

1. the new version,
2. whether the update is required,
3. each changelog item,
4. whether to build and publish,
5. final confirmation.

It then updates the version, embeds the worldwide manifest URL and global
server IP into the app, builds all platforms, copies the files into the update
server, creates `latest.json`, and verifies the published update.

The app checks for updates automatically when it opens. Settings also provides
a simple **Check for Updates** button without showing technical server details.

## Server files

```text
~/KittyAdventureUpdates/
├── files/
├── web/
├── logs/
├── run/
├── latest.json
├── server-info.json
└── UPDATE_SERVER_INFO.txt
```

The worldwide connection URL is `PUBLIC_MANIFEST_URL` inside
`UPDATE_SERVER_INFO.txt`.

The permanent public game URL is:

```text
https://kitty-adventure-zona.web.app/
```

The player-friendly downloads page is:

```text
https://kitty-adventure-zona.web.app/files/
```

The ngrok URL remains the update and download server:

```text
https://unstamped-revisit-underling.ngrok-free.dev/
```

The numeric public IP is recorded too, but it normally requires router port
forwarding. The ngrok HTTPS URL works without router port forwarding and is
the update-manifest address embedded into release builds. Each full release
also deploys the current web build to Firebase Hosting and notifies Bing,
DuckDuckGo's Bing-backed discovery path, and other IndexNow search engines.
