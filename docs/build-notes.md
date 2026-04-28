# Qoob Build Notes

## Environment Used

- Godot: `/Applications/Godot.app/Contents/MacOS/Godot`
- Godot version verified: 4.6.2 stable
- Export templates found at `~/Library/Application Support/Godot/export_templates/4.6.2.stable`
- GitHub repository: https://github.com/ApexTechConsulting/qoob

## Commands

Run tests:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_runner.gd
```

Regenerate procedural audio:

```sh
node tools/generate_audio.mjs
```

Regenerate the macOS app icon:

```sh
tools/generate_iconset.sh
```

Export macOS app:

```sh
mkdir -p dist
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release macOS dist/Qoob.app
ditto -c -k --keepParent dist/Qoob.app dist/Qoob-mac.zip
```

Launch:

```sh
open dist/Qoob.app
```

## Signing And Notarization

The current MVP export is not signed with an Apple Developer ID and is not notarized. This is expected for the local build. Do not describe the app as notarized until a Developer ID certificate and Apple notarization workflow have been configured.

If macOS blocks the local app, try:

```sh
xattr -dr com.apple.quarantine dist/Qoob.app
open dist/Qoob.app
```

For distribution outside this Mac, sign and notarize with Apple tooling before sharing broadly.

## GitHub

GitHub authentication was available during setup, so the repository was created and pushed. If a future checkout lacks authentication, use:

```sh
gh auth login
gh repo create qoob --public --source=. --remote=origin --push
```

