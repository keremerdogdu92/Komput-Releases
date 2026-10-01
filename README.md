# Komput Releases

Public distribution repository for Komput Windows releases.

## Recommended install

If Node.js/npm is available:

```powershell
npx @komput/agent@latest
```

Komput verifies the selected release metadata and bootstrap SHA-256 before installation.

## PowerShell bootstrap

For a bundled-runtime install that does not require system Node.js/npm:

```powershell
irm https://raw.githubusercontent.com/keremerdogdu92/Komput-Releases/main/install.ps1 | iex
```

After installation:

```powershell
komput status
komput connect chatgpt
komput setup blender
komput doctor blender
```

The legacy `openremote` command and `%LOCALAPPDATA%\OpenRemote` runtime layout remain temporarily available as compatibility internals while existing installations migrate to the Komput product identity.

Release artifacts and update manifests are published through GitHub Releases. Beta installations follow the mutable `channel-beta` manifest pointer; versioned release artifacts remain immutable.
