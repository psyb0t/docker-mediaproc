# 🎬 docker-mediaproc

[![Docker Hub](https://img.shields.io/docker/v/psyb0t/mediaproc?sort=semver&label=Docker%20Hub)](https://hub.docker.com/r/psyb0t/mediaproc)

Containerized media processing tools over SSH. Drop files in, run ffmpeg/sox/imagemagick over SSH, get your shit out. No shell access, no bullshit - just a locked-down Python wrapper that only lets you run what you're supposed to run.

## ⚡ Features

- **FFmpeg 7.1** with frei0r, LADSPA, and LV2 plugins - video effects, audio effects, all the good shit
- **Sox** - audio processing swiss army knife
- **ImageMagick** - image manipulation, conversion, thumbnails, whatever
- **2200+ fonts** - emoji, CJK, Arabic, Thai, Indic, monospace, you fuckin' name it
- **File ops over SSH** - `put`, `get`, `ls`, `rm`, `rmdir`, `rrmdir`, `mkdir` - all locked to `/work`, no volume mount needed from remote machines
- **Locked down** - Python wrapper validates every command, no shell access, no sneaky `&&` or `;` injection bullshit
- **SSH key auth only** - no passwords, no keyboard-interactive, just keys like a proper setup

## 📋 Table of Contents

- [⚡ Features](#-features)
- [🚀 Quick Start](#-quick-start)
  - [install.sh (Recommended)](#installsh-recommended)
  - [docker run](#docker-run)
- [🎯 Allowed Commands](#-allowed-commands)
  - [Media Tools](#media-tools)
  - [File Operations](#file-operations)
- [💡 Usage Examples](#-usage-examples)
  - [Media Tools](#media-tools-1)
  - [File Operations](#file-operations-1)
- [📂 Volumes](#-volumes)
- [⌨️ SSH Client Config](#️-ssh-client-config)
- [🔨 Building](#-building)
- [🔒 Security](#-security)
- [🔤 Included Fonts](#-included-fonts)
- [📝 License](#-license)

## 🚀 Quick Start

### install.sh (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/psyb0t/docker-mediaproc/main/install.sh | sudo bash
```

This sets up `~/.mediaproc/` with the docker-compose file, authorized_keys, and work directory, then drops a `mediaproc` command into `/usr/local/bin`. Uses your UID/GID so you don't end up with shit permissions on files like some fuckin' animal.

Add your SSH key and start it:

```bash
cat ~/.ssh/id_rsa.pub >> ~/.mediaproc/authorized_keys
mediaproc start -d
ssh -p 2222 mediaproc@localhost "ffmpeg -version"
```

```bash
mediaproc start           # foreground
mediaproc start -d        # detached
mediaproc start -d -p 22  # detached on custom port (default 2222)
mediaproc stop            # stop
mediaproc upgrade         # pull latest image, asks to stop/restart if running
mediaproc status          # show status
mediaproc logs            # show logs
```

### docker run

If you just wanna run it raw without the install script:

```bash
docker pull psyb0t/mediaproc

cat ~/.ssh/id_rsa.pub > authorized_keys
mkdir -p work

docker run -d \
  --name mediaproc \
  --restart unless-stopped \
  -p 2222:22 \
  -e "MEDIAPROC_UID=$(id -u)" \
  -e "MEDIAPROC_GID=$(id -g)" \
  -v $(pwd)/authorized_keys:/home/mediaproc/authorized_keys:ro \
  -v $(pwd)/work:/work \
  psyb0t/mediaproc

ssh -p 2222 mediaproc@localhost "ffmpeg -version"
```

## 🎯 Allowed Commands

That's it. That's the list. Everything else gets a nice "not allowed" message.

### Media Tools

| Command    | Description                                  |
| ---------- | -------------------------------------------- |
| `ffmpeg`   | Video/audio encoding, transcoding, filtering |
| `ffprobe`  | Media file analysis                          |
| `sox`      | Audio processing                             |
| `soxi`     | Audio file info                              |
| `convert`  | Image conversion/manipulation                |
| `identify` | Image file info                              |
| `magick`   | ImageMagick CLI                              |

### File Operations

All paths are relative to `/work`. You can't escape it - traversal attempts get blocked, absolute paths get remapped under `/work`.

| Command  | Description                                       |
| -------- | ------------------------------------------------- |
| `ls`     | List `/work` or a subdirectory                    |
| `put`    | Upload file from stdin                            |
| `get`    | Download file to stdout                           |
| `rm`     | Delete a file (not directories)                   |
| `mkdir`  | Create directory (recursive)                      |
| `rmdir`  | Remove empty directory                            |
| `rrmdir` | Remove directory and everything in it recursively |

## 💡 Usage Examples

### Media Tools

```bash
# Transcode video
ssh mediaproc@host "ffmpeg -i /work/input.mp4 -c:v libx264 /work/output.mp4"

# Get video info as JSON
ssh mediaproc@host "ffprobe -v quiet -print_format json -show_format /work/video.mp4"

# Apply frei0r glow effect
ssh mediaproc@host "ffmpeg -i /work/in.mp4 -vf frei0r=glow:0.5 /work/out.mp4"

# Convert audio format
ssh mediaproc@host "sox /work/input.wav /work/output.mp3"

# Resize image
ssh mediaproc@host "convert /work/input.png -resize 50% /work/output.png"

# Create thumbnail
ssh mediaproc@host "convert /work/input.jpg -thumbnail 200x200 /work/thumb.jpg"
```

### File Operations

Manage files in `/work` over SSH from any machine:

```bash
# Upload a file
ssh mediaproc@host "put input.mp4" < input.mp4

# Download a file
ssh mediaproc@host "get output.mp4" > output.mp4

# List files
ssh mediaproc@host "ls"
ssh mediaproc@host "ls subdir"

# Create a directory
ssh mediaproc@host "mkdir project1"

# Delete a file
ssh mediaproc@host "rm input.mp4"

# Delete an empty directory
ssh mediaproc@host "rmdir project1"

# Nuke a directory and everything in it
ssh mediaproc@host "rrmdir project1"
```

All paths are locked to `/work`. No escape, no traversal, no bullshit.

## 📂 Volumes

| Path                              | Description                                               |
| --------------------------------- | --------------------------------------------------------- |
| `/work`                           | Input/output files - your workspace                       |
| `/home/mediaproc/authorized_keys` | SSH public keys (mount read-only)                         |
| `/usr/share/fonts/custom`         | Extra fonts if the 2200+ aren't enough for your fancy ass |

## ⌨️ SSH Client Config

Stop typing port numbers like it's 1995. Add this kinda shit to `~/.ssh/config`:

```
Host mediaproc
    HostName localhost
    Port 2222
    User mediaproc
```

Then just: `ssh mediaproc "ffmpeg -version"`

## 🔨 Building

```bash
make build
```

## 🔒 Security

This thing is locked the fuck down:

- **No shell access** - every command goes through a Python wrapper that parses it with `shlex.split()` and executes via `os.execv()` - there is literally no shell involved at any point
- **Whitelist only** - if the command isn't in the allowed list, it doesn't run. Period.
- **No injection** - `&&`, `;`, `|`, `$()` and all that injection shit just becomes literal arguments to the binary. No shell means shell metacharacters are meaningless
- **SSH key auth only** - passwords disabled, keyboard-interactive disabled
- **No forwarding** - TCP forwarding, tunneling, agent forwarding, X11 - all disabled. This is a media processor, not your personal VPN

## 🔤 Included Fonts

Over 2200 fonts covering pretty much every script and use case:

- **Core**: DejaVu, Liberation, Ubuntu, Roboto, Open Sans
- **Emoji & CJK**: Noto Color Emoji, Noto Sans CJK (Chinese, Japanese, Korean)
- **Monospace**: Fira Code, Hack, Inconsolata
- **International**: Arabic, Thai, Khmer, Lao, Tibetan, Indic scripts

Need more? Mount your custom fonts to `/usr/share/fonts/custom` and the container will pick them up on startup. Font cache gets rebuilt automatically.

## 📝 License

This project is licensed under [WTFPL](LICENSE) - Do What The Fuck You Want To Public License.
