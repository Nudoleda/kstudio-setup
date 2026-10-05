# KStudio setup — public installer (code stays private)

Termux runtime setup for **KStudio IDE**, mirroring Darkian Studio's public
support repo: only the installer script, the extension-host JS, and compiled
release assets live here. No app source.

## Phone setup (one line in Termux from F-Droid)

```bash
pkg install curl; curl -fsSL https://raw.githubusercontent.com/Nudoleda/kstudio-setup/main/install.sh | bash
```

Then type `ksterm` to start the bridge, run `cat ~/.kstudio/token`,
paste the token into the KStudio app, and tap **Verify setup**.

| File | Purpose |
|---|---|
| `install.sh` | Base packages, per-language toolchains (`--all` / `--lang`), `ksterm` launcher on PATH, token + server start |
| `ksterm/ks-exthost.js` | Node extension host (fetched by `install.sh`) |
| Releases → `ksterm.jar` | Compiled bridge server (fetched by `install.sh`) |
