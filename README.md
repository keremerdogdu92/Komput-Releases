# OpenRemote Releases

Public distribution repository for OpenRemote Windows releases.

## Install from PowerShell

```powershell
irm https://raw.githubusercontent.com/keremerdogdu92/OpenRemote-Releases/main/install.ps1 | iex
```

The bootstrap resolves the current beta release, verifies the published SHA-256 metadata, installs OpenRemote per-user, and adds the `openremote` command to the user PATH.

After installation:

```powershell
openremote status
openremote setup blender
openremote doctor blender
```

`openremote setup blender` installs or repairs the optional Blender MCP integration. `openremote doctor blender` checks the local Blender MCP executable and Blender socket connection.

Release artifacts and update manifests remain available under GitHub Releases for the updater and manual diagnostics.
