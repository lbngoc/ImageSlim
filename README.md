# ImageSlim 🖼️

**English** · [Tiếng Việt](README.vi.md) · [繁體中文](README.zh-TW.md)

Shrink images straight from the Finder right-click menu on macOS.

## Features

- 🎯 **Three formats** — PNG, JPG/JPEG, WebP
- ⚡ **One right-click** — no app to open, no drag & drop
- 🛠️ **Self-installing** — pulls its own dependencies with Homebrew
- 🛡️ **Never loses the original** — the untouched file is kept as `name.orig.ext`
- 📦 **Only replaces when it wins** — a file is swapped only if the result is smaller
- 🔁 **Safe to re-run** — files that already have a backup are skipped, so quality never degrades twice
- 🔔 **One summary notification** per batch

## Supported formats

| Format | Tool | Setting | Notes |
|---|---|---|---|
| PNG | `pngquant` | quality 70–90 | Colour quantisation. Skipped when the result would be larger (exit 98) or fall below the quality floor (exit 99). |
| JPG/JPEG | `jpegoptim` | max 85, `--strip-all` | Metadata (EXIF, including orientation, and the ICC profile) is removed. |
| WebP | `cwebp` | quality 80 | Re-encoded through a temp file, never over its own input. |

## Requirements

- macOS
- Homebrew — `install.sh` installs it if missing (the official Homebrew installer is
  downloaded from GitHub and run; macOS may ask for your password during that step)

## Install

The URLs below point at `lbngoc/ImageSlim`, the fork that carries these changes;
swap `lbngoc` for `sacahan` once they are merged upstream.

### Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/lbngoc/ImageSlim/main/install.sh -o /tmp/imageslim-install.sh
less /tmp/imageslim-install.sh   # read it first if you like
bash /tmp/imageslim-install.sh
```

Piping it straight into a shell also works, but then you never read what runs:

```bash
curl -fsSL https://raw.githubusercontent.com/lbngoc/ImageSlim/main/install.sh | bash
```

Use `bash`, not `sh`. The script needs bash (`[[ ]]`, heredocs), so `sh` — which is
`dash` on many systems — will fail.

The URL follows the `main` branch, so it installs whatever is there at that moment. To
pin it, replace `main` with a tag or commit:

```bash
curl -fsSL https://raw.githubusercontent.com/lbngoc/ImageSlim/<tag-or-commit>/install.sh | bash
```

### From a clone

```bash
git clone https://github.com/lbngoc/ImageSlim.git
cd ImageSlim
bash install.sh
```

Both ways need nothing else — the script is self-contained.

What the installer does:

1. Checks that you are on macOS
2. Installs Homebrew when it is missing
3. `brew install pngquant jpegoptim webp`
4. Writes `~/Library/Services/ImageSlim (PNG_JPG_WEBP).workflow`
5. Enables the service in macOS `pbs` (a freshly added service is disabled by default on
   recent macOS versions — restarting Finder alone is not enough)
6. Restarts Finder

## Usage

1. Select one or more images in Finder
2. Right-click → **Quick Actions** → **ImageSlim (PNG/JPG/WEBP)**
3. Read the notification when it finishes

What you end up with:

```
photo.png        644 KB  →  212 KB      (compressed, keeps its name)
photo.orig.png   644 KB                 (untouched original)
IMG_0002.JPG     657 KB  →   54 KB
IMG_0002.orig.JPG 657 KB
```

Rules:

- The compressed result keeps the **original file name**; the old file is renamed to
  `name.orig.ext`.
- The swap happens only when the new file is **smaller**, otherwise nothing changes.
- If `name.orig.ext` already exists the file is **skipped**, so running the action twice
  cannot degrade the same image twice.
- Unsupported files are ignored; a missing tool only skips its own format, the rest of
  the batch still runs.

Notification examples:

| Situation | Notification |
|---|---|
| Something was compressed | `3 compressed, saved 2.3 MB` |
| Mixed | `1 compressed, saved 281 KB, 1 skipped` |
| Nothing to gain | `Nothing to optimize, 3 skipped` |
| Only unsupported files selected | no notification |

### Restoring an original

```bash
mv photo.orig.png photo.png
```

## Uninstall

```bash
rm -rf ~/Library/Services/"ImageSlim (PNG_JPG_WEBP).workflow"
killall Finder
```

The tools themselves can stay (other apps may use them) or be removed with
`brew uninstall pngquant jpegoptim webp`.

## How it works

```
install.sh
  ├─ macOS check
  ├─ Homebrew check / install
  ├─ brew install pngquant jpegoptim webp
  ├─ write ~/Library/Services/ImageSlim (PNG_JPG_WEBP).workflow
  │    ├─ Contents/Info.plist      NSServices entry (Finder only, public.image)
  │    ├─ Contents/version.plist
  │    └─ Contents/document.wflow  Automator "Run Shell Script" action
  ├─ enable the service in pbs
  └─ killall Finder
```

Technical details:

- The action runs under `/bin/zsh` and receives the selected files as arguments.
- The extension picks the tool: `png` → `pngquant`, `jpg|jpeg` → `jpegoptim`,
  `webp` → `cwebp`.
- Output goes to `mktemp -t imageslim`, sizes are compared with `stat -f%z`, and only
  then is the file swapped with `mv`. `jpegoptim` uses `--stdout` so it never writes
  over its input.
- A `trap` removes the temp file if the action is interrupted.

## Troubleshooting

| Problem | Fix |
|---|---|
| Quick Action not in the menu | See below |
| `Permission denied` | `chmod +x install.sh` and run it again |
| Missing tools | `brew install pngquant jpegoptim webp` |

### The Quick Action does not appear

On recent macOS a service dropped into `~/Library/Services/` stays disabled until `pbs`
has an entry for it, so `killall Finder` alone does nothing. `install.sh` already handles
this; to repair it by hand:

```bash
# 1. restart the service registry so it reloads its preferences
killall pbs; sleep 1
# 2. rescan ~/Library/Services
/System/Library/CoreServices/pbs -update
# 3. restart Finder so it rebuilds the menu
killall Finder
```

If it is still missing, check in this order:

1. **Select an image file first** — right-clicking empty folder space never shows
   image actions.
2. System Settings → Keyboard → Keyboard Shortcuts → **Services** → **Finder** and tick
   `ImageSlim (PNG/JPG/WEBP)`.
3. Confirm the service is registered at all:

   ```bash
   /System/Library/CoreServices/pbs -dump_pboard | grep -A3 ImageSlim
   ```

   No output means the bundle was never read — run `bash install.sh` again.
4. Verify the workflow itself still runs (this rules out a broken bundle):

   ```bash
   /usr/bin/automator -i ~/Desktop/test.png \
     ~/Library/Services/"ImageSlim (PNG_JPG_WEBP).workflow"
   ```
5. In rare cases you need to log out and back in before Finder rebuilds its menu.

### Removing the backup lock

A file with an existing `name.orig.ext` is skipped by design. To re-compress it at a
different quality, delete the backup first:

```bash
rm photo.orig.png
```

## Notes

- `jpegoptim --strip-all` removes EXIF, so photos that rely on an EXIF orientation flag
  may appear rotated afterwards. Recompress with `--strip-none` if that matters to you.
- Notifications are silent if Focus / Do Not Disturb is on, or if notifications are
  disabled for Automator in System Settings → Notifications.

## Author

Brian Han — [GitHub](https://github.com/sacahan)

## License

MIT License
